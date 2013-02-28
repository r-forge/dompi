#
# This function follows the outline presented in section 6 of
# the vignette for the "parallel" package written by R-Core.
#
setRngDoMPI <- function(cl, seed=NULL) {
  # save the current value of .Random.seed so it can be restored
  if (exists('.Random.seed', where=globalenv(), inherits=FALSE))
    saveseed <- get('.Random.seed', pos=globalenv(), inherits=FALSE)
  else
    saveseed <- NULL

  # set RNG to L'Ecuyer in order to generate .Random.seed values
  # to send to the workers, saving the previous value
  saverng <- RNGkind("L'Ecuyer-CMRG")

  # call set.seed if seed is not NULL
  if (! is.null(seed))
    set.seed(seed)

  # send a .Random.seed value to each worker in the cluster
  s <- .Random.seed
  for (i in seq(length=clusterSize(cl))) {
    s <- nextRNGStream(s)
    sendToWorker(cl, i, list(seed=s))
  }

  # restore the local RNG and .Random.seed
  RNGkind(saverng[1])
  if (is.null(saveseed))
    rm('.Random.seed', pos=globalenv())
  else
    assign('.Random.seed', saveseed, pos=globalenv())

  invisible(NULL)
}
