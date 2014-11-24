suppressMessages(library(bigmemory))
suppressMessages(library(biganalytics))
suppressMessages(library(iterators))
suppressMessages(library(doMPI))

cl <- startMPIcluster()
registerDoMPI(cl)

iseq <- function(n, ...) {
  it <- idiv(n, ...)
  i <- 1L
  nextEl <- function() {
    m <- as.integer(nextElem(it))
    j <- i
    i <<- i + m
    list(firstCol=j, lastCol=i-1L)
  }
  object <- list(nextElem=nextEl)
  class(object) <- c("abstractiter", "iter")
  object
}

x <- matrix(rnorm(10000), nrow=100, ncol=100)
ign <- as.big.matrix(x, type='double',
                     backingfile='x.bin',
                     descriptorfile='x.descr')

nw <- getDoParWorkers()
y <- foreach(i=iseq(ncol(x), chunks=nw), .combine='c',
             .packages='biganalytics') %dopar% {
  bx <- attach.big.matrix('x.descr')
  colmean(sub.big.matrix(bx, firstCol=i$firstCol, lastCol=i$lastCol,
                         backingpath=getwd()))
}

print(all.equal(y, colMeans(x)))

closeCluster(cl)
mpi.quit()
