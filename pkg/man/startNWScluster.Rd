\name{startNWScluster}
\alias{startNWScluster}
\title{Create and start an NWS cluster}
\description{
The \code{startNWScluster} function is used to start an NWS cluster
for use with doMPI.
}
\usage{
startNWScluster(count, verbose=FALSE, workdir=getwd(), logdir=workdir,
                enablemulticore=TRUE, includemaster=FALSE, timeout=60)
}
\arguments{
  \item{count}{Number of workers to spawn.}
  \item{verbose}{Indicates if verbose messages should be enabled.  Defaults to \code{FALSE}.}
  \item{workdir}{Working directory of the cluster workers.  Defaults to the master's
  working directory.}
  \item{logdir}{Directory to put the worker log files.  Defaults to \code{workdir}.}
  \item{enablemulticore}{Attempt to use the mclapply function on the worker nodes.
  Defaults to \code{TRUE}.}
  \item{includemaster}{Indicates if the master process should be counted as a load o the CPU.
  This will effect how many cores will be used on the local machine by mclapply,
  if a worker process is started on the local machine.  The default value is FALSE,
  since the master process doesn't tend to use much CPU with nws.  Defaults to \code{TRUE}.}
  \item{timeout}{Number of seconds to wait for the sleigh workers to start.}
}
\seealso{
  \code{\link[nws]{sleigh}}
}
\examples{
\dontrun{
# start and register an NWS cluster with two workers in verbose mode:
cl <- startNWScluster(workerCount=2, verbose=TRUE)
registerDoNWS(cl)
# and shut it down
closeCluster(cl)

# set the log directory to the current directory:
cl <- startNWScluster(workerCount=2, logDir='.', verbose=TRUE)
registerDoNWS(cl)
# and shut it down
closeCluster(cl)
}
}
\keyword{utilities}
