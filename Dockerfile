FROM centos:7
MAINTAINER "Daniel Farrell" danpf@uw.edu

# --builder
ARG BUILDER=cctbx

# number of processors for building
ARG NCPU=4

# update OS and install system packages for building
RUN yum -y update && \
    yum -y install gcc gcc-c++ autoconf libtool make python wget git svn \
        zlib zlib-devel bzip2 bzip2-devel \
        libX11 libX11-devel libXext libXext-devel \
        mesa-libGL mesa-libGL-devel mesa-libGLU mesa-libGLU-devel

# get bootstrap.py
RUN wget "https://raw.githubusercontent.com/cctbx/cctbx_project/master/libtbx/auto_build/bootstrap.py"

# get sources
RUN python bootstrap.py hot update --builder=${BUILDER}

# build dependencies
RUN python bootstrap.py base --builder=${BUILDER} --nproc=${NCPU}

# build
RUN python bootstrap.py build --builder=${BUILDER} --nproc=${NCPU}

# --builder
ARG BUILDER=molprobity

# get sources
RUN python bootstrap.py hot update --builder=${BUILDER}

# build dependencies
RUN python bootstrap.py base --builder=${BUILDER} --nproc=${NCPU}

# build
RUN python bootstrap.py build --builder=${BUILDER} --nproc=${NCPU}

WORKDIR /

RUN mkdir -p modules/chem_data && \
	cd modules/chem_data && \
	svn --quiet --non-interactive --trust-server-cert co svn://svn.code.sf.net/p/geostd/code/trunk geostd && \
	svn --quiet --non-interactive --trust-server-cert co https://github.com/rlabduke/mon_lib.git/trunk mon_lib && \
	svn --quiet --non-interactive --trust-server-cert co https://github.com/rlabduke/reference_data.git/trunk/Top8000/Top8000_rotamer_pct_contour_grids rotarama_data && \
	rm -rf rotarama_data/.svn && \
	svn --quiet --non-interactive --trust-server-cert --force co https://github.com/rlabduke/reference_data.git/trunk/Top8000/Top8000_ramachandran_pct_contour_grids rotarama_data && \
	svn --quiet --non-interactive --trust-server-cert co https://github.com/rlabduke/reference_data.git/trunk/Top8000/Top8000_cablam_pct_contour_grids cablam_data
ADD top8000_rama_z_dict.pkl modules/chem_data/rama_z/top8000_rama_z_dict.pkl
RUN cd / && \
	source build/setpaths.sh && \
	python modules/chem_data/cablam_data/rebuild_cablam_cache.py && \
	./build/bin/mmtbx.rebuild_rotarama_cache
