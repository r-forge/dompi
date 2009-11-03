#
# Copyright (c) 2009, Stephen B. Weston
#
# This is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# USA

# See master.R for information on the structure of the job, taskchunk,
# and resultchunk objects.

mklogger <- function(verbose, out=stdout()) {
  if (verbose) {
    function(fmt, ...) {
      xfmt <- paste(fmt, '\n', sep='')
      args <- list(...)
      msg <- if (length(args) > 0) {
        fun <- function(n) if (is.null(n)) 'NULL' else n
        do.call('sprintf', c(xfmt, lapply(args, fun)))
      } else {
        xfmt
      }
      if (length(msg) != 1)
        stop('logger does not like arguments with length != 1')
      cat(msg, file=out)
      flush(out)
    }
  } else {
    function(fmt, ...) NULL
  }
}

# toplevel worker function
workerLoop <- function(cl, cores, verbose, out=stdout()) {
  logger <- mklogger(verbose)
  logger('starting worker loop')

  # loop over jobs, which correspond to calls to foreach
  while (!is.null(envir <- bcastRecvFromMaster(cl))) {
    # get the job id from envir to sanity check tasks
    jid <- get('.$jid', envir)

    # perform job initialization
    logger('initializing for new job %d', jid)
    err <- jobInitialize(envir)

    # wait for tasks until you get a poison task
    logger('waiting for initial taskchunk...')
    taskchunk <- recvFromMaster(cl)
    checkTask(taskchunk, jid)

    while (! taskchunk$jobcomplete) {
      logger('executing taskchunk %d', taskchunk$tid)
      resultchunk <- executeTaskChunk(cl$workerid, taskchunk, envir, err, cores)

      logger('returning results for taskchunk %d', taskchunk$tid)
      sendToMaster(cl, resultchunk)

      logger('waiting for new taskchunk...')
      taskchunk <- recvFromMaster(cl)
      checkTask(taskchunk, jid)
    }

    # perform job cleanup
    logger('cleaning up after job', jid)
    jobCleanup(envir)
  }

  logger('shutting down')
  NULL
}

# sanity check taskchunks
checkTask <- function(taskchunk, jid) {
  # XXX could do more tests
  if (!identical(taskchunk$jid, jid))
    stop(sprintf('error: job id mismatch: %s != %s', taskchunk$jid, jid))
}

jobInitialize <- function(envir) {
  tryCatch({
    # load all required packages specified by the user
    pkgs <- get('.$packages', pos=envir)
    for (pkg in pkgs) {
      require(pkg, quietly=TRUE, character.only=TRUE)
    }

    # fix the parent environment of the execution environment
    parent.env(envir) <- globalenv()

    # execute the "initEnvir" function if specified
    ienv <- get('.$initEnvir', pos=envir)
    if (!is.null(ienv)) {
      # start creating the call object that will execute the initEnvir function
      init <- list(as.name('.$initEnvir'))

      # include extra arguments if function takes arguments
      if (length(formals(ienv)) > 0) {
         iargs <- get('.$initArgs', pos=envir)
         init <- c(init, list(envir), if (is.list(iargs)) iargs else NULL)
      }

      # execute the initEnvir function
      withCallingHandlers({
        eval(as.call(init), envir)
      },
      error=function(e) {
        e$calls <- sys.calls()
        signalCondition(e)
      })
    }

    NULL
  },
  error=function(e) {
    cat(sprintf('error executing initEnvir: %s\n', conditionMessage(e)))
    if (length(e$calls) > 0) {
      cat('traceback (most recent call first):\n')
      calls <- rev(e$calls)[c(-1, -2)]
      for (x in calls) {
        if (identical(x[[1]], as.name('withCallingHandlers')))
          break
        cat('> ')
        print(x)
      }
    }
    e
  })
}

jobCleanup <- function(envir) {
  tryCatch({
    # execute the "finalEnvir" function if specified
    fenv <- get('.$finalEnvir', pos=envir)
    if (!is.null(fenv)) {
      # start creating the call object that will execute the finalEnvir function
      final <- list(as.name('.$finalEnvir'))

      # include extra arguments if function takes arguments
      if (length(formals(fenv)) > 0) {
        fargs <- get('.$finalArgs', pos=envir)
        final <- c(final, list(envir), if (is.list(fargs)) fargs else NULL)
      }

      # execute the finalEnvir function
      withCallingHandlers({
        eval(as.call(final), envir)
      },
      error=function(e) {
        e$calls <- sys.calls()
        signalCondition(e)
      })
    }
  },
  error=function(e) {
    cat(sprintf('error executing finalEnvir: %s\n', conditionMessage(e)))
    if (length(e$calls) > 0) {
      cat('traceback (most recent call first):\n')
      calls <- rev(e$calls)[c(-1, -2)]
      for (x in calls) {
        if (identical(x[[1]], as.name('withCallingHandlers')))
          break
        cat('> ')
        print(x)
      }
    }
  })
}

# execute the tasks in a task chunk, possibly in parallel
executeTaskChunk <- function(workerid, taskchunk, envir, err, cores) {
  expr <- get('.$expr', pos=envir)

  nms <- names(taskchunk$argslist[[1]])
  executeTask <- if (is.null(err)) {
    function(args) {
      for (nm in nms) {
        assign(nm, args[[nm]], pos=envir)
      }

      # use withCallingHandlers to capture the traceback if an error occurs
      tryCatch({
        withCallingHandlers({
          eval(expr, envir)
        },
        error=function(e) {
          e$calls <- sys.calls()
          signalCondition(e)
        })
      },
      error=function(e) {
        cat(sprintf('error executing task: %s\n', conditionMessage(e)))
        if (length(e$calls) > 0) {
          cat('traceback (most recent call first):\n')
          calls <- rev(e$calls)[c(-1, -2)]
          for (x in calls) {
            if (identical(x[[1]], as.name('withCallingHandlers')))
              break
            cat('> ')
            print(x)
          }
        }
        e
      })
    }
  } else {
    function(...) err
  }

  list(numtasks=taskchunk$numtasks, tid=taskchunk$tid,
       workerid=workerid, jid=taskchunk$jid,
       resultslist = if (taskchunk$numtasks == 1)
         list(executeTask(taskchunk$argslist[[1]]))
       else if (cores <= 1)
         lapply(taskchunk$argslist, executeTask)
       else
         mclapply(taskchunk$argslist, executeTask, mc.cores=cores))
}
