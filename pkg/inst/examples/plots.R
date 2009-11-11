library(doMPI)

cl <- startMPIcluster(count=2, verbose=TRUE)
registerDoMPI(cl)

trials <- 10
n <- nrow(iris)
leaveout <- 2
chunkSize <- ceiling(trials / getDoParWorkers())
mpiopts <- list(chunkSize=chunkSize)

trash <- function(...) NULL
foreach(i=icount(trials), .combine=trash, .multicombine=TRUE,
        .packages='randomForest', .options.mpi=mpiopts) %dopar% {
  d <- iris[sample(n, n - leaveout),]
  rf <- randomForest(Species~., data=d, proximity=TRUE)
  png(filename=sprintf('MDSplot_%d.png', i))
  MDSplot(rf, d$Species)
  dev.off()
  NULL
}

closeCluster(cl)
mpi.finalize()
