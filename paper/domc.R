library(rbenchmark)
library(doMC)
registerDoMC()

seqfun <- function(m, n, a=1) {
  r <- double(m)
  for (i in 1:m) {
    x <- a
    for (j in 1:n)
      x <- 1 / (1 + x)
    r[i] <- x
  }
  r
}

parfun <- function(m, n, a=1) {
  foreach (icount(m)) %dopar% {
    x <- a
    for (j in 1:n)
      x <- 1 / (1 + x)
    x
  }
}

M <- 40
N <- 1000000
r <- benchmark(seqfun(M, N, 1), parfun(M, N, 1),
               columns=c("test", "replications", "elapsed", "relative"),
               order="relative", replications=4)
print(r)
