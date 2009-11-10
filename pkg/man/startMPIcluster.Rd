\name{startMPIcluster}
\alias{startMPIcluster}
\title{Create and start an MPI cluster}
\description{
The \code{startMPIcluster} function is used to start an MPI cluster.
}
\usage{
startMPIcluster(count, verbose=FALSE, workdir=getwd(), enablemulticore=TRUE,
                includemaster=FALSE)
}
\arguments{
  \item{count}{Number of workers to spawn.}
  \item{verbose}{Indicates if verbose messages should be enabled.}
  \item{workdir}{Working directory of the cluster workers.}
  \item{enablemulticore}{Attempt to use the mclapply function on the worker nodes.}
  \item{includemaster}{Indicates if the master process should be counted as a load on the CPU.
  This will effect how many cores will be used on the local machine by mclapply,
  if a worker process is started on the local machine.}
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
