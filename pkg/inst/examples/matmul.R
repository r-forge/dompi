library(doMPI)

cl <- startMPIcluster(count=3)
registerDoMPI(cl)

matmul <- function(x, y) {
  n <- ceiling(ncol(y) / getDoParWorkers())
  foreach(yc=iter(y, by='column', chunksize=n), .combine='cbind') %dopar% {
    x %*% yc
  }
}

m <- 6; n <- 5; p <- 4
x <- matrix(rnorm(m * n), m, n)
y <- matrix(rnorm(n * p), n, p)

z <- matmul(x, y)
print(z)
print(identical(z, x %*% y))

closeCluster(cl)
mpi.quit()
