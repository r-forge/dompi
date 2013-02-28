\name{setRngDoMPI}
\alias{setRngDoMPI}
\title{Set RNG}
\description{
The \code{setRngDoMPI} function is used to use parallel random number
generation on the specified cluster.  It uses the L'Ecuyer-CMRG
support in the base and parallel packages.
}
\usage{
setRngDoMPI(cl, seed=NULL)
}
\arguments{
  \item{cl}{The cluster to initialize.}
  \item{seed}{Passed to \code{set.seed} if not \code{NULL}.}
}
\examples{
\dontrun{
cl <- startMPIcluster(count=2)
setRngDoMPI(cl, seed=1234)
}
}
\keyword{utilities}
