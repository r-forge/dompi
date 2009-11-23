library(doMPI)

# create and register a doMPI cluster
cl <- startMPIcluster(count=3)
registerDoMPI(cl)

# define a parallel matrix multiple function
matmul <- function(x, y) {
  n <- ceiling(ncol(y) / getDoParWorkers())
  foreach(yc=iter(y, by='column', chunksize=n), .combine='cbind') %dopar% {
    x %*% yc
  }
}

# create some matrices
m <- 6; n <- 5; p <- 4
x <- matrix(rnorm(m * n), m, n)
y <- matrix(rnorm(n * p), n, p)

# execute matmul and then display and check the result
z <- matmul(x, y)
print(z)
print(identical(z, x %*% y))

# shutdown the cluster and quit
closeCluster(cl)
mpi.quit()
