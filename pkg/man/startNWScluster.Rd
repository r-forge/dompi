\name{startNWScluster}
\alias{startNWScluster}
\title{Create and start an NWS cluster}
\description{
The \code{startNWScluster} function is used to start an NWS cluster
for use with doMPI.
}
\usage{
startNWScluster(..., timeout=60, verbose=FALSE, workdir=getwd(), includemaster=FALSE)
}
\arguments{
  \item{\dots}{Arguments to be passed on to the \code{sleigh} function.}
  \item{timeout}{Number of seconds to wait for the sleigh workers to start.}
  \item{verbose}{Indicates if verbose messages should be enabled.}
  \item{workdir}{Working directory of the cluster workers.}
  \item{includemaster}{Indicates if the master should be counted as process.
  This will effect how many cores will be used on the local machine by mclapply,
  if a worker process is started on the local machine.  The default value is FALSE,
  since the master process doesn't tend to use much CPU with nws.}
}
\seealso{
  \code{\link[nws]{sleigh}}
}
\keyword{utilities}
