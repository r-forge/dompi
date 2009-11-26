\name{openMPIcluster}
\alias{openMPIcluster}
\title{Create an MPI cluster object}
\description{
The \code{openMPIcluster} function is used to create an MPI cluster
object in a cluster worker.  It is never executed by the master process.
Unlike \code{startMPIcluster}, it does not actually launch workers.  It
simply creates an MPI cluster object, which is passed to the
\code{workerLoop} function.  It is used internally in spawn mode, but it
also needs to be used in \code{doMPI} scripts that are started in
non-spawn mode.
}
\usage{
openMPIcluster(bcast=TRUE, comm=0, workerid=mpi.comm.rank(comm), verbose=FALSE)
}
\arguments{
  \item{bcast}{Indicates if a true MPI broadcast should be used to send
  shared \dQuote{job} data to the workers.  If \code{FALSE} is specified, the
  data is sent by separate messages to each worker, which is sometimes
  faster than using a broadcast.  So this option really controls whether
  to do a real or an emulated broadcast.  Defaults to \code{TRUE}.}
  \item{comm}{The MPI communicator number.  This should always be
  \code{0} when called from non-spawn mode.
  Defaults to \code{0}.}
  \item{workerid}{}
  \item{verbose}{Indicates if verbose messages should be enabled.
  Defaults to \code{FALSE}.}
}
\note{
Make sure that \code{openMPIcluster} is called consistently with
\code{startMPIcluster}, otherwise your program will hang.
In particular, make sure that \code{bcast} is set the same, and that
\code{comm} is \code{0}, which is the default value.
}
\examples{
\dontrun{
# make an MPI cluster object with emulated broadcast:
cl <- openMPIcluster(bcast=FALSE)
}
}
\keyword{utilities}
