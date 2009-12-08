# This example is based on an example from page 154 of
# "S Programming" by Venables and Ripley.  It's yet another
# inappropriate use of parallel computing, because the
# body of the loop is microscopic, but it does demonstrate
# the use of the '%:%' operator, as well as the '.final'
# argument.  The book demonstrates how to vectorize the
# example using the "outer" function, but I wanted a real
# example of nested for-loops.

suppressMessages(library(doMPI))

# Create and register an MPI cluster
cl <- startMPIcluster()
registerDoMPI(cl)

# Define a function that contains nested foreach loops
dd <- function() {
  opt <- list(chunkSize=100)
  tab <- function(x) tabulate(x + 82)
  foreach(a=0:9, .combine='c', .final=tab, .options.mpi=opt) %:%
    foreach(b=0:9, .combine='c') %:%
      foreach(d=0:9, .combine='c') %:%
        foreach(e=0:9, .combine='c') %dopar%
          (a*b - d*e)
}

# Execute dd and print the results
print(dd())

# Shutdown the cluster and quit
closeCluster(cl)
mpi.quit()
