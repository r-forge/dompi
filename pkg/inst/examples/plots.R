library(doMPI)

# create and register a doMPI cluster
cl <- startMPIcluster(2)
registerDoMPI(cl)

# initialize variables
trials <- 10
n <- nrow(iris)
leaveout <- 2

# define chunkSize so that each cluster worker gets a single "task chunk"
chunkSize <- ceiling(trials / getDoParWorkers())
mpiopts <- list(chunkSize=chunkSize)

# define a .combine function that throws away the "results"
trash <- function(...) NULL

# create the PNG files in parallel
foreach(i=icount(trials), .combine=trash, .multicombine=TRUE,
        .packages='randomForest', .options.mpi=mpiopts) %dopar% {
  d <- iris[sample(n, n - leaveout),]
  rf <- randomForest(Species~., data=d, proximity=TRUE)
  png(filename=sprintf('MDSplot_%d.png', i))
  MDSplot(rf, d$Species)
  dev.off()
  NULL
}

# shutdown the cluster and quit
closeCluster(cl)
mpi.quit()
