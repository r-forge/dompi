\name{setDoMpiRNG}
\alias{setDoMpiRNG}
\title{Set RNG}
\description{
The \code{setDoMpiRNG} function is used to use parallel random number
generation on the specified cluster.
}
\usage{
setDoMpiRNG(cl, seed)
}
\arguments{
  \item{cl}{The cluster object.}
  \item{seed}{Optional seed.}
}
\examples{
\dontrun{
cl <- startMPIcluster(count=2)
setDoMpiRNG(cl, seed=1234)
}
}
\keyword{utilities}
