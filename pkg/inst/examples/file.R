# This example shows how to use the .combine option to write results
# to a file created by the master process.  It demonstrates how the
# foreach .init and .final arguments are used as well, and how the
# first argument to the .combine function can be different than the
# subsequent arguments.  It also sets .inorder to TRUE for efficiency.

library(doMPI)

# Create and register an MPI cluster
cl <- startMPIcluster(2)
registerDoMPI(cl)

# Define a .combine function that writes its arguments to a file
writeResults <- function(fobj, ...) {
  foreach(r=list(...)) %do% write(r, file=fobj)
  fobj  # the return value must be the file object
}

# Create the output file that we will specify via the .init argument
f <- file('results.txt', 'w')

# Execute tasks of varying length in parallel, processing the results
# in any order, since order doesn't matter
foreach(i=1:10, .init=f, .final=close, .combine=writeResults,
        .multicombine=TRUE, .inorder=FALSE) %dopar% {
  Sys.sleep(max(rnorm(1, mean=3), 0))
  sprintf('This is the result of task number %d', i)
}

# Shut down the MPI cluster and finalize MPI
closeCluster(cl)
mpi.finalize()