library(doMPI)

usenws <- as.logical(Sys.getenv('USENWS', 'FALSE'))
verbose <- as.logical(Sys.getenv('VERBOSE', 'FALSE'))
im <- as.logical(Sys.getenv('INCLUDEMASTER', 'TRUE'))

cl <- if (usenws) {
  startNWScluster(workerCount=2, verbose=verbose, includemaster=im)
} else {
  startMPIcluster(count=2, verbose=verbose, includemaster=im)
}
registerDoMPI(cl)

x <- iris[which(iris[,5] != "setosa"), c(1,5)]
trials <- 10000

chunking <- as.logical(Sys.getenv('CHUNKING', 'TRUE'))
chunkSize <- if (chunking) ceiling(trials / getDoParWorkers()) else 1
mpiopts <- list(chunkSize=chunkSize)

ptime <- system.time({
  r <- foreach(icount(trials), .combine=cbind, .options.mpi=mpiopts) %dopar% {
    ind <- sample(100, 100, replace=TRUE)
    result1 <- glm(x[ind,2]~x[ind,1], family=binomial(logit))
    coefficients(result1)
  }
})[3]

cat(sprintf('Parallel time using doMPI on %d workers: %f\n',
            getDoParWorkers(), ptime))

closeCluster(cl)

sequential <- as.logical(Sys.getenv('SEQUENTIAL', 'FALSE'))
if (sequential) {
  stime <- system.time({
    r <- foreach(icount(trials), .combine=cbind) %do% {
      ind <- sample(100, 100, replace=TRUE)
      result1 <- glm(x[ind,2]~x[ind,1], family=binomial(logit))
      coefficients(result1)
    }
  })[3]

  cat(sprintf('Sequential time: %f\n', stime))
  cat(sprintf('Speed up for %d workers: %f\n',
              getDoParWorkers(), round(stime / ptime, digits=2)))
}
