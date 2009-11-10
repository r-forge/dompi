\name{startNWScluster}
\alias{startNWScluster}
\title{Create and start an NWS cluster}
\description{
The \code{startNWScluster} function is used to start an NWS cluster
for use with doMPI.
}
\usage{
startNWScluster(..., timeout=60, verbose=FALSE, workdir=getwd(),
                enablemulticore=TRUE, includemaster=FALSE)
}
\arguments{
  \item{\dots}{Arguments to be passed on to the \code{sleigh} function.}
  \item{timeout}{Number of seconds to wait for the sleigh workers to start.}
  \item{verbose}{Indicates if verbose messages should be enabled.}
  \item{workdir}{Working directory of the cluster workers.}
  \item{enablemulticore}{Attempt to use the mclapply function on the worker nodes.}
  \item{includemaster}{Indicates if the master process should be counted as a load o the CPU.
  This will effect how many cores will be used on the local machine by mclapply,
  if a worker process is started on the local machine.  The default value is FALSE,
  since the master process doesn't tend to use much CPU with nws.}
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
