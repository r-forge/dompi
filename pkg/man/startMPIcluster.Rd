\name{startMPIcluster}
\alias{startMPIcluster}
\title{Create and start an MPI cluster}
\description{
The \code{startMPIcluster} function is used to start an MPI cluster.
}
\usage{
startMPIcluster(count, verbose=FALSE, workdir=getwd(), logdir=workdir,
                maxcores=1, includemaster=TRUE)
}
\arguments{
  \item{count}{Number of workers to spawn.}
  \item{verbose}{Indicates if verbose messages should be enabled.  Defaults to \code{FALSE}.}
  \item{workdir}{Working directory of the cluster workers.  Defaults to the master's
  working directory.}
  \item{logdir}{Directory to put the worker log files.  Defaults to \code{workdir}.}
  \item{maxcores}{Maximum number of cores for workers to use.  Defaults to \code{1}.}
  \item{includemaster}{Indicates if the master process should be counted as a load on the CPU.
  This will effect how many cores will be used on the local machine by mclapply,
  if a worker process is started on the local machine.  Defaults to \code{TRUE}.}
}
\examples{
\dontrun{
# start and register an MPI cluster with two workers in verbose mode:
cl <- startMPIcluster(count=2, verbose=TRUE)
registerDoMPI(cl)
# and shut it down
closeCluster(cl)

# set the working directory to /tmp:
cl <- startMPIcluster(count=2, workdir='/tmp')
registerDoMPI(cl)
# and shut it down
closeCluster(cl)
}
}
\keyword{utilities}
