# NOTE:  I consider this to be a useful benchmark for comparing
# different parallel systems, but it is important to keep in
# mind that the tasks are rather small.  That is useful for
# finding out how much overhead different parallel programming
# systems add to task execution.  But because the tasks are small,
# it isn't really a great candidate for parallel programming.
# However, it isn't ridiculous either, and would be a very good
# example using hardware from a decade ago.
#
# Also note that because this is a benchmark, I am not actually
# combining the task results, but am throwing them away.  That
# allows me to test just the speed of the parallel programming
# system, not the speed of the combine mechanism in the foreach
# package.
#
# TODO Document the usage

suppressMessages(library(doMPI))

main <- function(args) {
  count <- if (mpi.comm.size(0) > 1) {
    mpi.comm.size(0) - 1
  } else {
    mpi.universe.size() - 1
  }
  bcast <- TRUE
  verbose <- FALSE
  profile <- FALSE
  forcePiggyback <- FALSE
  bcastThreshold <- 800
  cores <- 1
  sequential <- TRUE
  chunking <- TRUE
  wfile <- sprintf("MPI_%d_%s.log", mpi.comm.rank(0), Sys.info()[['user']])

  # Process the command line
  i <- 1
  while (i <= length(args)) {
    if (args[i] == '-n') {
      if (mpi.comm.size(0) > 1)
        stop('error: -n cannot be used in non-spawning mode')
      i <- i + 1
      if (is.na(args[i]))
        stop('error: -n takes a required numeric argument')
      count <- suppressWarnings(as.integer(args[i]))
      if (is.na(count))
        stop('error: -n takes a numeric argument')
    } else if (args[i] == '-emulate') {
      bcast <- FALSE
    } else if (args[i] == '-v') {
      verbose <- TRUE
    } else if (args[i] == '-profile') {
      profile <- TRUE
    } else if (args[i] == '-force') {
      forcePiggyback <- TRUE
    } else if (args[i] == '-threshold') {
      i <- i + 1
      if (is.na(args[i]))
        stop('error: -threshold takes a required numeric argument')
      bcastThreshold <- suppressWarnings(as.integer(args[i]))
      if (is.na(bcastThreshold))
        stop('error: -threshold takes a numeric argument')
    } else if (args[i] == '-cores') {
      i <- i + 1
      if (is.na(args[i]))
        stop('error: -cores takes a required numeric argument')
      cores <- suppressWarnings(as.integer(args[i]))
      if (is.na(cores))
        stop('error: -cores takes a numeric argument')
    } else {
      stop('error: illegal option: ', args[i])
    }
    i <- i + 1
  }

  # Check if this is the master or a cluster worker
  if (mpi.comm.rank(0) > 0) {
    # This is a cluster worker
    outfile <- if (verbose) wfile else "/dev/null"
    sinkWorkerOutput(outfile)
    cl <- openMPIcluster(bcast=bcast)
    workerLoop(cl, cores=cores, verbose=verbose)
  } else {
    if (forcePiggyback) {
      cat("Broadcasting is disabled: job data will always be piggy-backed\n")
    } else {
      if (bcast) {
        cat("Using true MPI broadcast for job data\n")
      } else {
        cat("Using emulated broadcast for job data\n")
      }
      cat(sprintf("Piggy-back/broadcast threshold is %d\n", bcastThreshold))
    }

    # This is the master
    # Create and register an MPI cluster
    cl <- startMPIcluster(count=count, bcast=bcast, verbose=verbose)
    registerDoMPI(cl)

    x <- iris[which(iris[,5] != "setosa"), c(1,5)]
    trials <- 10000

    chunkSize <- if (chunking) ceiling(trials / getDoParWorkers()) else 1
    opts <- list(chunkSize=chunkSize, profile=profile,
                 forcePiggyback=forcePiggyback,
                 bcastThreshold=bcastThreshold)
    trash <- function(...) NULL

    ptime <- system.time({
      foreach(icount(trials), .combine=trash, .multicombine=TRUE,
                   .options.mpi=opts) %dopar% {
        ind <- sample(100, 100, replace=TRUE)
        result1 <- glm(x[ind,2]~x[ind,1], family=binomial(logit))
        coefficients(result1)
      }
    })[3]

    cat(sprintf('Parallel time using doMPI on %d workers: %f\n',
                getDoParWorkers(), ptime))

    closeCluster(cl)

    if (sequential) {
      stime <- system.time({
        foreach(icount(trials), .combine=trash, .multicombine=TRUE) %do% {
          ind <- sample(100, 100, replace=TRUE)
          result1 <- glm(x[ind,2]~x[ind,1], family=binomial(logit))
          coefficients(result1)
        }
      })[3]

      cat(sprintf('Sequential time: %f\n', stime))
      cat(sprintf('Speed up for %d workers: %f\n',
                  getDoParWorkers(), round(stime / ptime, digits=2)))
    }
  }
}

# Catch errors so we can call mpi.quit
tryCatch({
  main(commandArgs(trailingOnly=TRUE))
},
error=function(e) {
  cat(sprintf('%s\n', conditionMessage(e)))
})

mpi.quit()
