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

# The job object is broadcast to the workers.
#
#   job            an environment with the following elements:
#     .$expr
#     .$packages
#     .$initEnvir
#     .$initArgs
#     .$finalEnvir
#     .$finalArgs
#     .$jid
#
#   taskchunk      a list with the following elements:
#     numtasks     number of tasks in this taskchunk
#     tid          base task id in this task chunk
#     argslist     list of lists of arguments to the worker function
#     jid          id of the job associated with this task chunk
#     jobcomplete  is this a null, "job is complete" task
#                  if true, the workers wait for another job object
#                  to be broadcast
#
#   resultchunk    a list with the following elements:
#     numtasks     number of tasks results in this resultchunk
#     tid          base task id associated with this resultchunk
#     resultslist  list of task results
#     workerid     id of the worker that generated these task results
#     jid          id of the job associated with this task chunk
#   (should there be an error indicator?)
#

master <- function(cl, expr, it, envir, packages, verbose, chunkSize, info,
                   initEnvir, initArgs, finalEnvir, finalArgs) {
  # choose a random id for this job for sanity checking
  jid <- sample(1000000, 1)

  # set the enclosing environment of initEnvir and finalEnvir to
  # be the execution environment
  if (!is.null(initEnvir))
    environment(initEnvir) <- envir
  if (!is.null(finalEnvir))
    environment(finalEnvir) <- envir

  # put extra data into execution environmment to be sent to cluster
  assign('.$expr', expr, pos=envir)
  assign('.$packages', packages, pos=envir)
  assign('.$initEnvir', initEnvir, pos=envir)
  assign('.$initArgs', initArgs, pos=envir)
  assign('.$finalEnvir', finalEnvir, pos=envir)
  assign('.$finalArgs', finalArgs, pos=envir)
  assign('.$jid', jid, pos=envir)

  # broadcast the execution environment to the cluster workers
  if (verbose)
    cat(sprintf('broadcasting data to cluster workers for job id %d\n', jid))
  bcastSendToCluster(cl, envir)

  submitTaskChunk <- function(workerid, tid) {
    argslist <- as.list(truncate(it, chunkSize))
    numtasks <- length(argslist)
    if (numtasks > 0) {
      taskchunk <- list(argslist=argslist, numtasks=numtasks, tid=tid,
                        jid=jid, jobcomplete=FALSE)
      sendToWorker(cl, workerid, taskchunk)
    }
    numtasks
  }

  submitPoisonTask <- function(workerid) {
    taskchunk <- list(argslist=NULL, numtasks=0, tid=-1, jid=jid,
                      jobcomplete=TRUE)
    sendToWorker(cl, workerid, taskchunk)
    0
  }

  processResultChunk <- function(resultchunk) {
    if (!identical(resultchunk$jid, jid))
      stop(sprintf('error: job id mismatch: %s != %s', resultchunk, jid))

    tid <- resultchunk$tid

    for (i in seq(length=resultchunk$numtasks)) {
      accumulate(it, resultchunk$resultslist[[i]], tid)
      tid <- tid + 1
    }
  }

  moretasks <- TRUE  # are there more tasks to be submitted?
  tid <- 1           # next tid
  submitted <- 0     # number of taskchunks submitted
  returned <- 0      # number of resultslist returned

  # submit a taskchunk to each worker in the cluster
  # unless we run out of tasks
  while (submitted < clusterSize(cl) && moretasks) {
    workerid <- submitted + 1  # workerid ranges from 1 to clusterSize(cl)
    if (verbose)
      cat(sprintf('sending initial taskchunk to worker %d\n', workerid))
    numtasks <- submitTaskChunk(workerid, tid)
    if (numtasks > 0) {
      tid <- tid + numtasks
      submitted <- submitted + 1
    } else {
      moretasks <- FALSE
    }
  }

  # send poison tasks to any remaining workers in case we ran out of
  # tasks before every cluster worker got at least one taskchunk.
  # these workers will immediately wait for a new job object to be
  # broadcast by the master.
  i <- submitted
  while(i < clusterSize(cl)) {
    i <- i + 1
    if (verbose)
      cat(sprintf('sending initial poison task to worker %d\n', i))
    submitPoisonTask(i)
  }

  # wait for results, and submit new tasks to the workers that return them
  while (moretasks) {
    # wait for a result from any worker
    if (verbose) cat('waiting for task results from any worker...\n')
    resultchunk <- recvFromAnyWorker(cl)
    returned <- returned + 1
    if (verbose) {
      cat(sprintf('got task results %d from worker %d\n',
                  resultchunk$tid, resultchunk$workerid))
    }

    # submit another taskchunk for the worker before processing the result
    numtasks <- submitTaskChunk(resultchunk$workerid, tid)
    if (numtasks > 0) {
      tid <- tid + numtasks
      submitted <- submitted + 1
    } else {
      # we didn't submit a real task, so submit a poison task
      submitPoisonTask(resultchunk$workerid)
      moretasks <- FALSE
    }

    processResultChunk(resultchunk)
  }

  # wait for results to be returned
  while (returned < submitted) {
    # wait for a resultchunk from any worker
    if (verbose) cat('waiting for task results from any worker...\n')
    resultchunk <- recvFromAnyWorker(cl)
    returned <- returned + 1
    if (verbose) {
      cat(sprintf('got task results %d from worker %d\n',
                  resultchunk$tid, resultchunk$workerid))
    }

    # submit a poison task and then process the resultchunk
    submitPoisonTask(resultchunk$workerid)
    processResultChunk(resultchunk)
  }
}

# this returns an iterator that returns no more than "n" values
# from the specified iterator.
truncate <- function(it, n) {
  it <- iter(it)

  nextEl <- function() {
    if (n > 0)
      n <<- n - 1
    else
      stop('StopIteration')

    nextElem(it)
  }

  obj <- list(nextElem=nextEl)
  class(obj) <- c('abstractiter', 'iter')
  obj
}
