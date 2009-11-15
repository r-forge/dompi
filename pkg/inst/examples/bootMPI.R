library(doMPI)

# create and register a doMPI cluster
cl <- startMPIcluster(2)
registerDoMPI(cl)

# initialize variables
x <- iris[which(iris[,5] != "setosa"), c(1,5)]
trials <- 10000

# define chunkSize so that each cluster worker gets a single "task chunk"
chunkSize <- ceiling(trials / getDoParWorkers())
mpiopts <- list(chunkSize=chunkSize)

# perform the bootstrapping in parallel
r <- foreach(icount(trials), .combine='cbind', .options.mpi=mpiopts) %dopar% {
  ind <- sample(100, 100, replace=TRUE)
  result1 <- glm(x[ind,2]~x[ind,1], family=binomial(logit))
  structure(coefficients(result1), names=NULL)
}

# print the resulting matrix
print(r)

# shutdown the cluster and quit
closeCluster(cl)
mpi.quit()
