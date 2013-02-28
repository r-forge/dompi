# This example shows how to setup the cluster workers
# to use parallel random number generation using the
# new setDoMpiRNG function.

suppressMessages(library(doMPI))

# Create and register an MPI cluster
cl <- startMPIcluster()
registerDoMPI(cl)

# Check if we get "repeatable" results
for (n in 1:3) {
  # Initialize parallel RNG
  setDoMpiRNG(cl, seed=1234)

  # Execute a foreach loop that uses random numbers
  r <- foreach(i=icount(clusterSize(cl)), .combine='c') %dopar% {
    Sys.sleep(3)
    as.integer(runif(1, max=1000))
  }
  print(r)
}

# Shutdown the cluster and quit
closeCluster(cl)
mpi.quit()
