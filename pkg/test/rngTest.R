suppressMessages(library(doMPI))
library(itertools)

test01 <- function() {
  n <- 4
  RNGkind("L'Ecuyer-CMRG")
  expected <- as.list(iRNGStream(.Random.seed), n=n+1)[-(n+1)]
  print(expected)

  cl <- startMPIcluster(n, comm=3)
  on.exit(closeCluster(cl))

  setRngDoMPI(cl)
  registerDoMPI(cl)
  actual <- foreach(icount(n)) %dopar% .Random.seed
  print(actual)

  identical(actual, expected)
}

print(test01())
