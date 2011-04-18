suppressMessages(library(foreach))
library(itertools)

dd.seq.1 <- function(n=10, vec=seq(0, length=n)) {
  val <- NULL
  for (a in vec)
    for (b in vec)
      for (d in vec)
        for (e in vec)
          val <- c(val, a * b - d * e)

  table(val)
}

dd.seq.2 <- function(n=10, vec=seq(0, length=n)) {
  val <- double(length(vec) ^ 4)
  i <- 1
  for (a in vec)
    for (b in vec)
      for (d in vec)
        for (e in vec) {
          val[i] <- a * b - d * e
          i <- i + 1
        }

  table(val)
}

dd.dopar.1 <- function(n=10, vec=seq(0, length=n)) {
  val <-
    foreach(a=vec, .combine='c') %:%
      foreach(b=vec, .combine='c') %:%
        foreach(d=vec, .combine='c') %:%
          foreach(e=vec, .combine='c') %dopar% {
            a * b - d * e
          }

  table(val)
}

dd.dopar.2 <- function(n=10, vec=seq(0, length=n)) {
  val <-
    foreach(x=product(a=vec, b=vec, d=vec, e=vec), .combine='c') %dopar% {
      x$a * x$b - x$d * x$e
    }

  table(val)
}

dd.dopar.3 <- function(n=10, vec=seq(0, length=n)) {
  val <-
    foreach(x=product(a=vec, b=vec), .combine='c') %dopar% {
      v <- NULL
      for (d in vec)
        for (e in vec)
          v <- c(v, x$a * x$b - d * e)
      v
    }

  table(val)
}

dd.dopar.4 <- function(n=10, vec=seq(0, length=n)) {
  val <-
    foreach(a=vec, .combine='c') %:%
      foreach(b=vec, .combine='c') %dopar% {
        v <- NULL
        for (d in vec)
          for (e in vec)
            v <- c(v, a * b - d * e)
        v
      }

  table(val)
}

dd.dopar.5 <- function(n=10, vec=seq(0, length=n)) {
  val <-
    foreach(a=vec, .combine='c') %:%
      foreach(b=vec, .combine='c') %dopar% {
        v <- double(length(vec) ^ 2)
        i <- 1
        ab <- a * b
        for (d in vec)
          for (e in vec) {
            v[i] <- ab - d * e
            i <- i + 1
          }
        v
      }

  table(val)
}

dd.dopar.6 <- function(n=10, vec=seq(0, length=n)) {
  val <-
    foreach(x=product(a=vec, b=vec), .combine='c') %dopar% {
      v <- double(length(vec) ^ 2)
      i <- 1
      ab <- x$a * x$b
      for (d in vec)
        for (e in vec) {
          v[i] <- ab - d * e
          i <- i + 1
        }
      v
    }

  table(val)
}

dd.dopar.7 <- function(n=10, vec=seq(0, length=n)) {
  val <-
    foreach(a=vec, .combine='c') %dopar% {
      v <- double(length(vec) ^ 3)
      i <- 1
      for (b in vec)
        for (d in vec)
          for (e in vec) {
            v[i] <- a * b - d * e
            i <- i + 1
          }
      v
    }

  table(val)
}

dd.dopar.8 <- function(n=10, vec=seq(0, length=n)) {
  mv2 <- max(vec) ^ 2
  offset <- mv2 + 1
  nbins <- 2 * mv2 + 1

  val <-
    foreach(a=vec, .combine='+') %dopar% {
      v <- double(length(vec) ^ 3)
      i <- 1
      for (b in vec) {
        ab <- a * b
        for (d in vec) {
          for (e in vec) {
            v[i] <- ab - d * e
            i <- i + 1
          }
        }
      }
      tabulate(v + offset, nbins=nbins)
    }

  y <- array(val, dim=nbins, dimnames=list(val=as.character(-mv2:mv2)))
  class(y) <- 'table'
  y
}

library(compiler)
dd.seq.1.comp <- cmpfun(dd.seq.1)
dd.seq.2.comp <- cmpfun(dd.seq.2)

dd.seq.3 <- function(n=10, vec=seq(0, length=n)) {
  val <- outer(vec, vec, '*')
  val <- outer(val, val, '-')
  table(val)
}

dd.seq.4 <- function(n=10, vec=seq(0, length=n)) {
  n <- length(vec)
  mv2 <- max(vec) ^ 2
  offset <- mv2 + 1
  nbins <- 2 * mv2 + 1

  val <- integer(nbins)

  for (a in vec) {
    ab <- a * vec
    for (d in vec)
      val <- val + tabulate(ab - rep(d * vec, each=n) + offset, nbins=nbins)
  }

  y <- array(val, dim=nbins, dimnames=list(val=as.character(-mv2:mv2)))
  class(y) <- 'table'
  y
}

dd.seq.3.comp <- cmpfun(dd.seq.3)
dd.seq.4.comp <- cmpfun(dd.seq.4)

dd.dopar.9 <- function(n=10, vec=seq(0, length=n)) {
  n <- length(vec)
  mv2 <- max(vec) ^ 2
  offset <- mv2 + 1
  nbins <- 2 * mv2 + 1

  val <-
    foreach(a=vec, .combine='+') %dopar% {
      v <- integer(nbins)
      ab <- a * vec
      for (d in vec)
        v <- v + tabulate(ab - rep(d * vec, each=n) + offset, nbins=nbins)
      v
    }

  y <- array(val, dim=nbins, dimnames=list(val=as.character(-mv2:mv2)))
  class(y) <- 'table'
  y
}

dd.int <- function(offset, nbins, ab, d, e) {
  tabulate(ab - rep(as.vector(d %*% t(e)), each=length(ab)) + offset,
           nbins=nbins)
}

dd.seq.5 <- function(n=10, vec=seq(0, length=n)) {
  n <- length(vec)
  mv2 <- max(vec) ^ 2
  offset <- mv2 + 1
  nbins <- 2 * mv2 + 1

  val <- dd.int(offset, nbins, as.integer(vec %*% t(vec)), vec, vec)

  y <- array(val, dim=nbins, dimnames=list(val=as.character(-mv2:mv2)))
  class(y) <- 'table'
  y
}

dd.seq.5.comp <- cmpfun(dd.seq.5)

dd.dopar.10 <- function(n=10, vec=seq(0, length=n)) {
  n <- length(vec)
  mv2 <- max(vec) ^ 2
  offset <- mv2 + 1
  nbins <- 2 * mv2 + 1

  cs <- 50  # should be controlled by option

  val <-
    foreach(a=isplitVector(vec, chunkSize=cs), .combine='+') %dopar% {
      foreach(b=isplitVector(vec, chunkSize=cs), .combine='+') %do% {
        ab <- as.vector(a %*% t(b))
        foreach(d=isplitVector(vec, chunkSize=cs), .combine='+') %:%
          foreach(e=isplitVector(vec, chunkSize=cs), .combine='+') %do%
            dd.int(offset, nbins, ab, d, e)
        }
    }

  y <- array(val, dim=nbins, dimnames=list(val=as.character(-mv2:mv2)))
  class(y) <- 'table'
  y
}

dd.dopar.11 <- function(n=10, vec=seq(0, length=n)) {
  n <- length(vec)
  mv2 <- max(vec) ^ 2
  offset <- mv2 + 1
  nbins <- 2 * mv2 + 1

  cs <- 50  # should be controlled by option

  val <-
    foreach(a=isplitVector(vec, chunkSize=cs), .combine='+') %:%
      foreach(b=isplitVector(vec, chunkSize=cs), .combine='+') %dopar% {
        ab <- as.vector(a %*% t(b))
        foreach(d=isplitVector(vec, chunkSize=cs), .combine='+') %:%
          foreach(e=isplitVector(vec, chunkSize=cs), .combine='+') %do%
            dd.int(offset, nbins, ab, d, e)
      }

  y <- array(val, dim=nbins, dimnames=list(val=as.character(-mv2:mv2)))
  class(y) <- 'table'
  y
}
