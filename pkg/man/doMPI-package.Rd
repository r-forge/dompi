\name{doMPI-package}
\alias{doMPI-package}
\alias{doMPI}
\docType{package}
\title{
The doMPI Package
}
\description{
The \code{doMPI} package provides a parallel backend for the \code{foreach}
package. It is similar to the \code{doSNOW} package, but uses \code{Rmpi}
directly. This allows it to do more, and execute more efficiently.
It also uses the multicore package to execute tasks across multiple
cores on the worker nodes.
}
\details{
Help documentation is available on the following subjects:
\tabular{ll}{
\code{startMPIcluster} \tab Create and start an MPI cluster object\cr
\code{registerDoMPI} \tab Register a cluster object to be used with \%dopar\%\cr
\code{closeCluster} \tab Shutdown and close a cluster object\cr
\code{clusterSize} \tab Return the number of workers associated with a cluster object\cr
}

For a complete list of functions with individual help pages,
use \code{library(help="doMPI")}.
}
\keyword{package}
