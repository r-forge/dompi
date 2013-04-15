# This example shows how to setup the cluster workers to use parallel
# random number generation using the itertools "iRNGSubStream" function.
# It uses a different random number substream for each task so that the
# results are repeatable regardless of the number of workers or which
# worker executes what task.  Note that the results show that the
# task results are the same on subsequent runs even though different
# workers generate those results.
# 
# The approach was inspired by the "doRNG" package.

suppressMessages(library(doMPI))
library(itertools)

# Create and register an MPI cluster
cl <- startMPIcluster()
registerDoMPI(cl)

# Used to set the RNG on the cluster workers
initEnvir <- function(envir) RNGkind("L'Ecuyer-CMRG")
mpiopts <- list(initEnvir=initEnvir)

# Verify that we get repeatable results
nc <- 4
nr <- 20
isleep <- irunif(1, max=5)
r <-
  foreach(1:nc, .combine='cbind') %:%
    foreach(1:nr, sleep=isleep, seed=iRNGSubStream(42),
            .combine='rbind', .options.mpi=mpiopts) %dopar% {
      assign('.Random.seed', seed, pos=globalenv())
      Sys.sleep(sleep)  # Randomize task length
      data.frame(rank=mpi.comm.rank(0), result=as.integer(runif(1, max=1000)))
    }

print(r)

# Shutdown the cluster and quit
closeCluster(cl)
mpi.quit()
