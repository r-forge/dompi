local({
  # set default option values
  workdir <- Sys.getenv('TMPDIR', '/tmp')
  includemaster <- FALSE  # assume master doesn't use much cpu time
  verbose <- FALSE

  # process the command line
  for (arg in commandArgs(trailingOnly=TRUE)) {
    i <- regexpr('=', arg)
    opt <- substring(arg, 1, i - 1)
    val <- substring(arg, i + 1)

    if (opt == 'WORKDIR') {
      workdir <- val
    } else if (opt == 'INCLUDEMASTER') {
      includemaster <- as.logical(val)
    } else if (opt == 'VERBOSE') {
      vebose <- as.logical(val)
    } else {
      warning('ignoring unrecognized option: ', opt)
    }
  }

  # load all packages that we need explicitly to avoid messages to stdout
  suppressMessages(library(methods))  # because we're using Rscript
  suppressMessages(library(doMPI))

  # initialize MPI
  comm <- 1
  intercomm <- 2
  mpi.comm.get.parent(intercomm)
  mpi.intercomm.merge(intercomm, 1, comm)
  mpi.comm.set.errhandler(comm)
  mpi.comm.disconnect(intercomm)

  # our worker id is our rank
  workerid <- mpi.comm.rank(comm)

  # set the current working directory as specified
  # XXX anything to do in case of failure?
  try(setwd(workdir), silent=TRUE)

  # open a worker log file
  outfile <- if (verbose) {
    sprintf('MPI_%d_%s.log', workerid, Sys.info()[['user']])
  } else {
    '/dev/null'
  }
  sinkWorkerOutput(outfile)

  if (verbose)
    cat("starting MPI worker\n")

  # get the nodename of all the workers
  nodename <- Sys.info()[['nodename']]
  nodelist <- list()
  nodelist[[as.character(workerid)]] <- nodename
  nodelist <- mpi.allgather.Robj(nodelist, comm)

  # get the name of the master node and then remove it from nodelist
  masternode <- nodelist[['0']]
  nodelist[['0']] <- NULL

  # using nodelist, figure out how many processes got started on our node
  # and determine our position in that list
  wids <- as.integer(names(nodelist))
  nodev <- unlist(nodelist)
  idx <- which(nodev == nodename)
  numprocs <- length(idx)
  id <- which(sort(wids[idx]) == workerid)

  # possibly adjust the number of cores if we're on the master node
  numcores <- multicore:::detectCores()
  if (includemaster && nodename == masternode)
    numcores <- numcores - 1

  # compute the number of cores available to us
  # this will determine if we will ever use mclapply
  cores <- numcores %/% numprocs + (id < numcores %% numprocs)
  if (verbose)
    cat(sprintf('numprocs: %d, id: %d, numcores: %d, cores: %d\n',
                numprocs, id, numcores, cores))

  # this is where all the work is done
  cl <- doMPI:::openMPIcluster(workerid)
  doMPI:::workerLoop(cl, cores, verbose)

  # shutdown MPI
  mpi.comm.disconnect(comm)
  mpi.quit()
})
