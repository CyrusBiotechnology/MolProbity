FROM centos:7

# --builder
ARG BUILDER=cctbx

# number of processors for building
ARG NCPU=8

# update OS and install system packages for building
RUN yum -y update && \
    yum -y install gcc gcc-c++ autoconf libtool make python wget git svn which php-cli mlocate zip java libXt.x86_64 \
        zlib zlib-devel bzip2 bzip2-devel xorg-x11-font-utils \
        libX11 libX11-devel libXext libXext-devel \
        mesa-libGL mesa-libGL-devel mesa-libGLU mesa-libGLU-devel python-six && updatedb

# COPY base_tmp.tgz base_tmp.tgz
# RUN cd / && tar xf base_tmp.tgz

# get bootstrap.py
# RUN wget "https://raw.githubusercontent.com/cctbx/cctbx_project/master/libtbx/auto_build/bootstrap.py"
COPY bootstrap.py bootstrap.py

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
ADD entrypoint.sh /entrypoint.sh
# WARNING YOU MIGHT NEED TO source build/setpaths.sh again before you run your script!!!
RUN cd / && \
	source build/setpaths.sh && \
	python modules/chem_data/cablam_data/rebuild_cablam_cache.py && \
	./build/bin/mmtbx.rebuild_rotarama_cache && \
	cd molprobity && ./setup.sh && chmod +x /entrypoint.sh

# You should run the command: /entrypoint.sh php -S 0.0.0.0:8000 -c /molprobity/config/php.ini
ENTRYPOINT ["/entrypoint.sh"]
