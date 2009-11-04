\name{startMPIcluster}
\alias{startMPIcluster}
\title{Create and start an MPI cluster}
\description{
The \code{startMPIcluster} function is used to start an MPI cluster.
}
\usage{
startMPIcluster(count, verbose=FALSE, workdir=getwd(), includemaster=FALSE)
}
\arguments{
  \item{count}{Number of workers to spawn.}
  \item{verbose}{Indicates if verbose messages should be enabled.}
  \item{workdir}{Working directory of the cluster workers.}
  \item{includemaster}{Indicates if the master should be counted as process.
  This will effect how many cores will be used on the local machine by mclapply,
  if a worker process is started on the local machine.}
}
\keyword{utilities}
