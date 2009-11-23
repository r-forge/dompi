\name{startMPIcluster}
\alias{startMPIcluster}
\title{Create and start an MPI cluster}
\description{
The \code{startMPIcluster} function is used to start an MPI cluster.
}
\usage{
startMPIcluster(count, verbose=FALSE, workdir=getwd(), logdir=workdir,
                maxcores=1, includemaster=TRUE, bcast=TRUE)
}
\arguments{
  \item{count}{Number of workers to spawn.}
  \item{verbose}{Indicates if verbose messages should be enabled.
  Defaults to \code{FALSE}.}
  \item{workdir}{Working directory of the cluster workers.
  Defaults to the master's working directory.}
  \item{logdir}{Directory to put the worker log files.
  Defaults to \code{workdir}.}
  \item{maxcores}{Maximum number of cores for workers to use.
  Defaults to \code{1}.}
  \item{includemaster}{Indicates if the master process should be counted
  as a load on the CPU.
  This will effect how many cores will be used on the local machine by
  mclapply, if a worker process is started on the local machine.
  Defaults to \code{TRUE}.}
  \item{bcast}{Indicates if MPI broadcast should be used to send
  shared ``job'' data to the workers.  If \code{FALSE} is specified, the
  data is sent by separate messages to each worker, which is sometimes
  faster than using a broadcast.  Defaults to \code{TRUE}.}
}
\note{
The \code{startMPIcluster} function will return an MPI cluster object of
different classes, depending on the \code{bcast} option.  This is
because broadcasting is implemented as a method on the MPI cluster
object, and that method is implemented differently in the different
classes.

Also note that the \code{bcast} option has no effect if the
backend-specific \code{forcepiggyback} option is used with
\code{foreach}, since ``piggy-backing'' is an altermative way to send
the job data to the workers in separate messages.

So there are currently three ways that the job data can be sent to the
workers: piggy-backed with the first task to each worker, broadcast, or
sent in separate messages.  Which method is best will presumably depend
on your hardware and your MPI implementation.
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
