# This example shows how to setup the cluster workers to use parallel
# random number generation using the doMPI-specific "seed" option.  It
# uses a different random number substream for each task chunk so that
# the results are repeatable regardless of the number of workers or
# which worker executes what task chunk.  Note that the results show
# that the task results are the same on subsequent runs even though
# different workers generate those results.
# 
# The approach was inspired by the "doRNG" package.

suppressMessages(library(doMPI))

# Create and register an MPI cluster
cl <- startMPIcluster()
registerDoMPI(cl)

trials <- 4
w <- clusterSize(cl)

cat("Default chunkSize\n")
fun <- function(ignore) {
  foreach(sleep=irunif(1, max=5, count=4*w),
          .combine='rbind',
          .options.mpi=list(seed=42)) %dopar% {
    Sys.sleep(sleep)  # Randomize task length
    data.frame(rank=mpi.comm.rank(0), result=as.integer(runif(1, max=1000)))
  }
}
r <- lapply(1:trials, fun)
print(do.call('cbind', r))

cat("chunkSize is 3\n")
fun <- function(ignore) {
  foreach(sleep=irunif(1, max=5, count=4*w),
          .combine='rbind',
          .options.mpi=list(chunkSize=3, seed=42)) %dopar% {
    Sys.sleep(sleep)  # Randomize task length
    data.frame(rank=mpi.comm.rank(0), result=as.integer(runif(1, max=1000)))
  }
}
r <- lapply(1:trials, fun)
print(do.call('cbind', r))

# Shutdown the cluster and quit
closeCluster(cl)
mpi.quit()
