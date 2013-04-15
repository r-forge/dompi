# This example shows how to setup the cluster workers
# to use parallel random number generation using the
# itertools "iRNGSubStream" function.
#
# This uses an approach inspired by the "doRNG" package.

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
      assign('.Random.seed', seed, pos=.GlobalEnv)
      Sys.sleep(sleep)  # Randomize task length
      data.frame(rank=mpi.comm.rank(0), result=as.integer(runif(1, max=1000)))
    }

print(r)

# Shutdown the cluster and quit
closeCluster(cl)
mpi.quit()
