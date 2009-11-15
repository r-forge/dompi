# This example comes from the first example program in the first edition
# of "Using MPI" by William Gropp, Ewing Lusk, and Anthony Skjellum.
# It may have taken a significant amount of compute time in 1994,
# but not now.  But it's an interesting example of using vectorization
# with parallelization.

library(doMPI)

# Create and register an MPI cluster
cl <- startMPIcluster(2)
registerDoMPI(cl)

# Define a "parallel pi" function
ppi <- function(n=1000) {
  w <- getDoParWorkers()
  h <- 1 / n
  f <- function(s) h * s

  foreach(i=1:w, .combine='sum', .multicombine=TRUE, .final=f) %dopar% {
    x <- h * (seq(i, n, by=w) - 0.5)
    sum(4 / (1 + x * x))
  }
}

# Execute the "parallel pi" function and print the result
print(ppi())

# Shut down the MPI cluster and quit
closeCluster(cl)
mpi.quit()
