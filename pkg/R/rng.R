setRngDoMPI <- function(cl, seed=NULL) {
  # save the current value of .Random.seed so it can be restored
  if (exists('.Random.seed', where=globalenv(), inherits=FALSE))
    saveseed <- get('.Random.seed', pos=globalenv(), inherits=FALSE)
  else
    saveseed <- NULL

  # set RNG to L'Ecuyer in order to generate .Random.seed values
  # to send to the workers
  saverng <- RNGkind("L'Ecuyer-CMRG")

  # call set.seed if seed is not NULL
  if (!is.null(seed))
    set.seed(seed)

  # send a .Random.seed value to each worker
  s <- .Random.seed
  for (i in seq(length=clusterSize(cl))) {
    sendToWorker(cl, i, list(seed=s))
    s <- nextRNGStream(s)
  }

  # restore the local RNG and .Random.seed
  RNGkind(saverng[1])
  if (is.null(saveseed))
    rm('.Random.seed', pos=globalenv())
  else
    assign('.Random.seed', saveseed, pos=globalenv())

  invisible(NULL)
}
