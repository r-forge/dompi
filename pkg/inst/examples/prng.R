# This example shows how to setup the cluster workers
# to use parallel random number generation using the
# new setRngDoMPI function.

suppressMessages(library(doMPI))

# Create and register an MPI cluster
cl <- startMPIcluster()
registerDoMPI(cl)

# Verify that we get repeatable results
cat("Repeatable results\n")
for (n in 1:3) {
  # Initialize parallel RNG
  setRngDoMPI(cl, seed=42)

  r <- foreach(sleep=irunif(1, max=5, count=clusterSize(cl)),
               .combine='c') %dopar% {
    Sys.sleep(sleep)
    as.integer(runif(1, max=1000))
  }
  print(r)
}

# Check that we don't get repeatable results due to load imbalance
cat(sprintf("Only first %d results are guaranteed repeatable\n", clusterSize(cl)))
for (n in 1:3) {
  # Initialize parallel RNG
  setRngDoMPI(cl, seed=42)

  r <- foreach(sleep=irunif(1, max=5, count=4 * clusterSize(cl)),
               .combine='rbind') %dopar% {
    Sys.sleep(sleep)
    data.frame(rank=mpi.comm.rank(0), result=as.integer(runif(1, max=1000)))
  }
  print(r)
}

# Shutdown the cluster and quit
closeCluster(cl)
mpi.quit()
