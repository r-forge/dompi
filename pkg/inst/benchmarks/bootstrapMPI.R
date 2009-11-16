#
# NOTE:  I consider this to be a useful benchmark for comparing
# different parallel systems, but it is important to keep in
# mind that the tasks are rather small.  That is useful for
# finding out how much overhead different parallel programming
# systems add to task execution.  But because the tasks are small,
# it isn't really a great candidate for parallel programming.
# However, it isn't ridiculous either, and would be a very good
# example using hardware from a decade ago.
#
# Also note that because this is a benchmark, I am not actually
# combining the task results, but am throwing them away.  That
# allows me to test just the speed of the parallel programming
# system, not the speed of the combine mechanism in the foreach
# package.
#

library(doMPI)

usenws <- as.logical(Sys.getenv('USENWS', 'FALSE'))
count <- as.integer(Sys.getenv('COUNT', '2'))
verbose <- as.logical(Sys.getenv('VERBOSE', 'FALSE'))
im <- as.logical(Sys.getenv('INCLUDEMASTER', 'TRUE'))
maxcores <- as.integer(Sys.getenv('MAXCORES', '1'))

cl <- if (usenws) {
  startNWScluster(count=count, verbose=verbose, includemaster=im,
                  maxcores=maxcores)
} else {
  startMPIcluster(count=count, verbose=verbose, includemaster=im,
                  maxcores=maxcores)
}
registerDoMPI(cl)

x <- iris[which(iris[,5] != "setosa"), c(1,5)]
trials <- 10000

chunking <- as.logical(Sys.getenv('CHUNKING', 'TRUE'))
chunkSize <- if (chunking) ceiling(trials / getDoParWorkers()) else 1
mpiopts <- list(chunkSize=chunkSize)
trash <- function(...) NULL

ptime <- system.time({
  foreach(icount(trials), .combine=trash, .multicombine=TRUE,
               .options.mpi=mpiopts) %dopar% {
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
    foreach(icount(trials), .combine=trash, .multicombine=TRUE) %do% {
      ind <- sample(100, 100, replace=TRUE)
      result1 <- glm(x[ind,2]~x[ind,1], family=binomial(logit))
      coefficients(result1)
    }
  })[3]

  cat(sprintf('Sequential time: %f\n', stime))
  cat(sprintf('Speed up for %d workers: %f\n',
              getDoParWorkers(), round(stime / ptime, digits=2)))
}

if (!usenws) {
  mpi.quit()
}
