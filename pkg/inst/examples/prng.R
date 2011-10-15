# This example shows how to setup the cluster workers
# to use parallel random number generation using the
# rsprng package.

suppressMessages(library(doMPI))

# Create and register an MPI cluster
cl <- startMPIcluster()
registerDoMPI(cl)

# Initialize the workers to use rsprng for parallel random number
# generation.  This implementation assumes that if there are N workers,
# the first N tasks will all be executed by different workers, thus
# initializing all N workers.  That is true for doMPI, but isn't a
# general requirement for foreach backends.  This implementation also
# assumes that there is a persistent set of workers.  Again, this is
# true for doMPI, but not for doMC in particular.
initSPRNG <- function(seed=8765) {
  nstream <- getDoParWorkers()
  foreach(streamno=seq_len(nstream)-1L, .packages='rsprng') %dopar% {
    .Call('r_init_sprng', 0L, as.integer(streamno), as.integer(nstream),
          as.integer(seed), 0L, PACKAGE='rsprng')
    RNGkind('user')
    NULL
  }
  invisible()
}

# Initialize parallel RNG
initSPRNG(7777442)

# Execute a foreach loop that uses random numbers
r <- foreach(i=icount(100), .combine='c') %dopar% {
  as.integer(runif(1, max=1000))
}
print(r)

# Shutdown the cluster and quit
closeCluster(cl)
mpi.quit()
