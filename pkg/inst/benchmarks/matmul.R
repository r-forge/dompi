library(doMPI)

m <- 2000
n <- 1200
p <- 1200

count <- as.integer(Sys.getenv('COUNT', '3'))
bcast <- as.logical(Sys.getenv('BCAST', 'TRUE'))
verbose <- as.logical(Sys.getenv('VERBOSE', 'FALSE'))
profile <- as.logical(Sys.getenv('PROFILE', 'FALSE'))
forcepiggyback <- as.logical(Sys.getenv('FORCEPIGGYBACK', 'FALSE'))

cl <- startMPIcluster(count=count, bcast=bcast, verbose=verbose)
registerDoMPI(cl)

matmul <- function(x, y, profile=FALSE, forcepiggyback=FALSE) {
  n <- ceiling(ncol(y) / getDoParWorkers())
  opts <- list(profile=profile, forcepiggyback=forcepiggyback)
  foreach(yc=iter(y, by='column', chunksize=n), .combine='cbind',
          .options.mpi=opts) %dopar% {
    x %*% yc
  }
}

x <- matrix(rnorm(m * n), m, n)
y <- matrix(rnorm(n * p), n, p)

# gc(FALSE)
# Rprof()
stime <- proc.time()[3]
z <- matmul(x, y, profile, forcepiggyback)
etime <- proc.time()[3] - stime
# Rprof(NULL)

cat(sprintf('Time for matrix multiply with %s and %d workers: %f\n',
            getDoParName(), getDoParWorkers(), etime))

closeCluster(cl)
mpi.quit()
