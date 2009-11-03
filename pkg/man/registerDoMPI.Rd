\name{registerDoMPI}
\alias{registerDoMPI}
\title{registerDoMPI}
\description{
The \code{registerDoMPI} function is used to register the MPI parallel backend
with the foreach package.
}
\usage{
registerDoMPI(cl)
}
\arguments{
  \item{cl}{The MPI cluster object to use for parallel execution.}
}
\seealso{
  \code{\link{startMPIcluster}}
}

\keyword{utilities}
