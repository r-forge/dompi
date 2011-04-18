library(compiler)
library(rbenchmark)
library(foreach)
registerDoSEQ()

forfun <- function(m, n, a=1) {
  r <- double(m)
  for (i in 1:m) {
    x <- a
    for (j in 1:n)
      x <- 1 / (1 + x)
    r[i] <- x
  }
  r
}

foreachfun <- function(m, n, a=1) {
  foreach (icount(m)) %do% {
    x <- a
    for (j in 1:n)
      x <- 1 / (1 + x)
    x
  }
}

forfunc <- cmpfun(forfun)
foreachfunc <- cmpfun(foreachfun)


M <- 40
N <- 1000000
r <- benchmark(forfun(M, N, 1),  foreachfun(M, N, 1),
               forfunc(M, N, 1), foreachfunc(M, N, 1),
               columns=c("test", "replications", "elapsed", "relative"),
               order="relative", replications=4)
print(r)
