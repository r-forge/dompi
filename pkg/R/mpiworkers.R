#
# Copyright (c) 2009, Stephen B. Weston
#
# This is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# USA

# these variables are used to cache a "cluster" objects
getMPIcluster <- NULL
setMPIcluster <- NULL

local({
  cl <- NULL
  getMPIcluster <<- function() cl
  setMPIcluster <<- function(new) cl <<- new
})

# this is called by the user to create an mpi cluster object
startMPIcluster <- function(count, verbose=FALSE, workdir=getwd(),
                            logdir=workdir, maxcores=1,
                            includemaster=TRUE, bcast=TRUE) {
  # I think this restriction is currently necessary
  if (mpi.comm.rank(0) != 0) {
    warning('perhaps you should use "-np 1" from mpirun/orterun?')
    stop('startMPIcluster should only be executed from rank 0 of comm 0')
  }

  cl <- getMPIcluster()
  if (!is.null(cl)) {
    if (missing(count) || count == cl$workerCount)
      cl
    else
      stop(sprintf("an MPI cluster of size %d already running",
                   cl$workerCount))
  } else if (mpi.comm.size(0) > 1) {
    if (missing(count)) {
      count <- mpi.comm.size(0) - 1
    } else if (count != mpi.comm.size(0) - 1) {
      # XXX a bit confusing
      stop(sprintf("an MPI cluster of size %d was started", mpi.comm.size(0) - 1))
    }

    cl <- list(comm=0L, workerCount=count, workerid=0, verbose=verbose)
    class(cl) <- if (bcast) {
      c("mpicluster", "dompicluster")
    } else {
      c("nbmpicluster", "mpicluster", "dompicluster")
    }
    setMPIcluster(cl)
    cl
  } else {
    comm <- 1L
    intercomm <- 2L
    if (mpi.comm.size(comm) > 0) {
      stop(paste("an MPI cluster already exists:", comm))
    }

    rscript <- file.path(R.home(), "bin", "Rscript")
    script <- system.file("RMPIworker.R", package="doMPI")
    args <- c(script,
              sprintf("WORKDIR=%s", workdir),
              sprintf("LOGDIR=%s", logdir),
              sprintf("MAXCORES=%d", maxcores),
              sprintf("INCLUDEMASTER=%s", includemaster),
              sprintf("BCAST=%s", bcast),
              sprintf("VERBOSE=%s", verbose))

    procname <- mpi.get.processor.name()
    nodename <- Sys.info()[['nodename']]
    universesize <- mpi.universe.size()

    if (verbose) {
      cat(sprintf("Master processor name: %s; nodename: %s\n", procname, nodename))
      cat(sprintf("Size of MPI universe: %d\n", universesize))
    }

    if (missing(count)) {
      if (universesize > 1) {
        count <- universesize - 1
      } else {
        stop('count must be specified in this case')
      }
    }

    if (verbose) {
      cat(sprintf("Spawning %d workers using the command:\n", count))
      cat(sprintf("  %s %s\n", rscript, paste(args, collapse=" ")))
    }
    count <- mpi.comm.spawn(slave=rscript, slavearg=args,
                            nslaves=count, intercomm=intercomm)

    if (mpi.intercomm.merge(intercomm, 0, comm)) {
      mpi.comm.set.errhandler(comm)
      mpi.comm.disconnect(intercomm)
    } else {
      stop("error merging the comm for master and slaves")
    }

    # participate in making the nodelist, but the master doesn't use it
    # the workers use it for deciding how many cores to use
    nodelist <- list('0'=nodename)
    ## nodelist <- list('0'=procname)
    nodelist <- mpi.allgather.Robj(nodelist, comm)

    cl <- list(comm=comm, workerCount=count, workerid=0, verbose=verbose)
    class(cl) <- if (bcast) {
      c("mpicluster", "dompicluster")
    } else {
      c("nbmpicluster", "mpicluster", "dompicluster")
    }
    setMPIcluster(cl)
    cl
  }
}

clusterSize.mpicluster <- function(cl, ...) {
  cl$workerCount
}

# mpicluster method for shutting down a cluster object
closeCluster.mpicluster <- function(cl, ...) {
  tag <- 33  # worker tag
  for (workerid in seq(length=cl$workerCount)) {
    mpi.send.Robj(NULL, workerid, tag, cl$comm)
  }

  setMPIcluster(NULL)

  if (cl$comm != 0) {
    mpi.comm.disconnect(cl$comm)
  }

  invisible(NULL)
}

bcastSendToCluster.mpicluster <- function(cl, data, ...) {
  mpi.bcast(data, 4, 0, cl$comm)
}

bcastSendToCluster.nbmpicluster <- function(cl, data, ...) {
  tag <- 33L  # worker tag

  ## I was using the following in the for-loop:
  # mpi.send(data, 4, dest, tag, cl$comm)

  for (dest in seq(length=cl$workerCount))
    .Call("mpi_send", data, 4L, dest, tag, cl$comm, PACKAGE='Rmpi')
}

sendToWorker.mpicluster <- function(cl, workerid, robj, ...) {
  tag <- 33  # worker tag
  mpi.send.Robj(robj, workerid, tag, cl$comm)
}

recvFromAnyWorker.mpicluster <- function(cl, ...) {
  tag <- 22  # master tag
  status <- 0
  mpi.probe(mpi.any.source(), tag, cl$comm, status)
  srctag <- mpi.get.sourcetag(status)
  mpi.recv.Robj(srctag[1], srctag[2], cl$comm)
}

############################
# worker methods start here
############################

# this is called by the cluster workers to create an mpi cluster object
openMPIcluster <- function(bcast, comm, workerid=mpi.comm.rank(comm),
                           verbose=FALSE) {
  # XXX need to think about this
  obj <- list(comm=comm, workerCount=mpi.comm.size(comm),
              workerid=workerid, verbose=verbose)
  class(obj) <- if (bcast) {
    c('mpicluster', 'dompicluster')
  } else {
    c('nbmpicluster', 'mpicluster', 'dompicluster')
  }
  obj
}

bcastRecvFromMaster.mpicluster <- function(cl, datalen, ...) {
  unserialize(mpi.bcast(raw(datalen), 4, 0, cl$comm))
}

bcastRecvFromMaster.nbmpicluster <- function(cl, datalen, ...) {
  tag <- 33  # worker tag
  unserialize(mpi.recv(raw(datalen), 4, 0, tag, cl$comm))
}

sendToMaster.mpicluster <- function(cl, robj, ...) {
  tag <- 22  # master tag
  mpi.send.Robj(robj, 0, tag, cl$comm)
}

recvFromMaster.mpicluster <- function(cl, ...) {
  tag <- 33  # worker tag
  mpi.recv.Robj(0, tag, cl$comm)
}
