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
It also uses the \code{multicore} package to execute tasks across multiple
cores on the worker nodes.  This is can give very good performance on a
computer cluster with multicore processors.
}
\details{
There are several backend-specific options that can be specified when using
\code{doMPI}.  They are specified to \code{foreach} as a list using the
\code{.options.mpi} argument.  The currently supported options are:

\tabular{ll}{
\code{chunkSize} \tab Number of tasks to send at a time to the cluster workers\cr
\code{info} \tab Display extra information, particularly about exported variables\cr
\code{initEnvir} \tab A function to be called on each worker before executing any tasks\cr
\code{initArgs} \tab List of extra arguments to pass to the \code{initEnvir} function\cr
\code{finalEnvir} \tab A function to be called on each worker after executing all tasks\cr
\code{finalArgs} \tab List of extra arguments to pass to the \code{finalEnvir} function\cr
}

The \code{chunkSize} option is particularly important, since it can be
much more efficient to send more than one task at a time to the workers,
particularly when the tasks execute quickly.  Also, it can allow the
workers to execute those tasks in parallel using the \code{mclapply}
function from the \code{multicore} package.

The \code{initEnvir} option is useful for preparing the workers to
execute the subsequent tasks.  The execution environment is passed as
the first argument to this function.  That allows you to define new
variables in the environment, for example.  If \code{initArgs} is
defined, the contents of the list will be passed as arguments to the
\code{initEnvir} function after the environment object.

The \code{finalEnvir} option is useful for ``finalizing'' the execution
environment.  It works pretty much the same as the \code{initEnvir}
function, getting extra arguments from a list specified with the
\code{finalArgs} option.

Additional documentation is available on the following functions:

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
