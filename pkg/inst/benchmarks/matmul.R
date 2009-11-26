# This isn't an example.  It's a benchmark, so it has a number
# of options to control the execution of the benchmark.
# That makes it too complicated for an example, although the
# complexity has nothing to do with parallel computing.
#
# TODO Document the usage

suppressMessages(library(doMPI))

# Define a parallel matrix multiply function
matmul <- function(x, y, profile=FALSE, forcePiggyback=FALSE,
                   bcastThreshold=800) {
  n <- ceiling(ncol(y) / getDoParWorkers())
  opts <- list(profile=profile, forcePiggyback=forcePiggyback,
               bcastThreshold=bcastThreshold)
  foreach(yc=iter(y, by='column', chunksize=n), .combine='cbind',
          .options.mpi=opts) %dopar% {
    x %*% yc
  }
}

# Main program executed by master and workers
main <- function(args) {
  # Size of the matrices
  m <- 2000
  n <- 1200
  p <- 1200

  # Default option values
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
    cl <- openMPIcluster(bcast=bcast, verbose=verbose)
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

    # Create some matrices
    x <- matrix(rnorm(m * n), m, n)
    y <- matrix(rnorm(n * p), n, p)

    # Execute matmul and report the time
    stime <- proc.time()[3]
    z <- matmul(x, y, profile, forcePiggyback)
    etime <- proc.time()[3] - stime
    cat(sprintf('Time for matrix multiply with %s and %d workers: %f\n',
                getDoParName(), getDoParWorkers(), etime))

    # Shutdown the cluster
    closeCluster(cl)
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
