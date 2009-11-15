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
                            logdir=workdir, maxcores=64,
                            includemaster=TRUE) {
  # I think this restriction is currently necessary
  if (mpi.comm.rank(0) != 0) {
    warning('perhaps you should use "-n 1" from mpirun/orterun?')
    stop('startMPIcluster should only be executed from rank 0 of comm 0')
  }

  # I think this warning is useful, but I'm still studying the issue
  if (mpi.comm.size(0) > 1) {
    warning(sprintf('the size of comm 0 is %d', mpi.comm.size(0)))
    warning('perhaps you should use "-n 1" from mpirun/orterun?')
  }

  cl <- getMPIcluster()
  if (!is.null(cl)) {
    if (missing(count) || count == cl$workerCount)
      cl
    else
      stop(sprintf("an MPI cluster of size %d already running",
                   cl$workerCount))
  } else {
    comm <- 1
    intercomm <- 2
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

    cl <- list(workerCount=count)
    class(cl) <- c("mpicluster", "cluster")
    setMPIcluster(cl)
    cl
  }
}

clusterSize.mpicluster <- function(cl) {
  cl$workerCount
}

# mpicluster method for shutting down a cluster object
closeCluster.mpicluster <- function(cl, ...) {
  comm <- 1
  mpi.bcast.Robj(NULL, 0, comm)
  setMPIcluster(NULL)
  invisible(mpi.comm.disconnect(comm))
}

bcastSendToCluster.mpicluster <- function(cl, robj) {
  comm <- 1
  mpi.bcast.Robj(robj, 0, comm)
}

sendToWorker.mpicluster <- function(cl, workerid, robj) {
  tag <- 33  # worker tag
  comm <- 1
  mpi.send.Robj(robj, workerid, tag, comm)
}

recvFromAnyWorker.mpicluster <- function(cl) {
  tag <- 22  # master tag
  comm <- 1

  ## snow does it this way, but I don't know why
  ## possibly for historic reasons?
  # status <- 0
  # mpi.probe(mpi.any.source(), tag, comm, status)
  # srctag <- mpi.get.sourcetag(status)
  # mpi.recv.Robj(srctag[1], srctag[2], comm)

  mpi.recv.Robj(mpi.any.source(), tag, comm)
}

############################
# worker methods start here
############################

# this is called by the cluster workers to create an mpi cluster object
openMPIcluster <- function(workerid) {
  obj <- list(workerid=workerid)
  class(obj) <- c('mpicluster', 'cluster')
  obj
}

bcastRecvFromMaster.mpicluster <- function(cl) {
  comm <- 1
  mpi.bcast.Robj(NULL, 0, comm)
}

sendToMaster.mpicluster <- function(cl, robj) {
  tag <- 22  # master tag
  comm <- 1
  mpi.send.Robj(robj, 0, tag, comm)
}

recvFromMaster.mpicluster <- function(cl) {
  tag <- 33  # worker tag
  comm <- 1
  mpi.recv.Robj(0, tag, comm)
}
