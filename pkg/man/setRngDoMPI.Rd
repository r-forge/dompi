\name{setRngDoMPI}
\alias{setRngDoMPI}
\alias{PRNG}
\title{Setup parallel RNG on a doMPI cluster}
\description{
The \code{setRngDoMPI} function initializes the workers
of a doMPI cluster to use parallel random number generation.
To do this, it uses the \code{"L'Ecuyer-CMRG"}
RNG support provided by the \pkg{base} and \pkg{parallel} packages.

Note that the goal of \code{setRngDoMPI} is to insure that the cluster
workers each generate different streams of random numbers, not to
insure repeatable results.  Repeatable results are problematic since
tasks are assigned to the cluster workers as they return previous
results.  This can be very important for achieving good performance,
but it means that a given task may be executed by a different worker
at different times, and therefore will be executed with different
random data.  See the prng.R and prng2.R files in the examples directory
for more information on this subject.

This function follows the outline presented in section 6 of
the vignette for the \pkg{parallel} package written by R-Core.
}
\usage{
setRngDoMPI(cl, seed=NULL)
}
\arguments{
  \item{cl}{The doMPI cluster to initialize.}
  \item{seed}{Used to seed the random number generators on the
    cluster workers if not \code{NULL}.
    Note that the use of \code{seed} does not guarantee repeatable
    results because the tasks are not guaranteed to be repeatably
    executed by the same cluster workers.}
}
\seealso{
  \code{\link{startMPIcluster}},
  \code{\link[parallel]{nextRNGStream}}, \code{\link{RNG}}
}
\examples{
\dontrun{
cl <- startMPIcluster(count=2)
setRngDoMPI(cl, seed=1234)
}
}
\keyword{utilities}
