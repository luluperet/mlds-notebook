FROM jupyter/all-spark-notebook

ARG TEST_ONLY_BUILD

USER root

# Install all OS dependencies for openai gym
RUN apt-get update && apt-get install -yq --no-install-recommends \
    python-numpy \
    python-dev \
    cmake \
    zlib1g-dev \
    libjpeg-dev \
    xvfb \
    libav-tools \
    xorg-dev \
    python-opengl \
    libboost-all-dev \
    libsdl2-dev \
    swig \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install ffmpeg for video handling
RUN echo "deb http://ftp.uk.debian.org/debian jessie-backports main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -yq --no-install-recommends ffmpeg

# Switch back to jovyan to avoid accidental container running as root
USER $NB_USER
RUN conda update -n base conda

# Add channels to conda to install custom packages
RUN conda config --add channels menpo       # for opencv

# Set the working directory
WORKDIR /home/$NB_USER/work

# Install binary packages with conda from requirements-conda.txt.
# Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# use notebook-friendly backends in these images
#ONBUILD COPY requirements-conda.txt /home/jovyan/work
#ONBUILD RUN conda install --quiet --yes --file requirements-conda.txt && \
            #conda remove --quiet --yes --force qt pyqt && \
            #conda clean -tipsy

# Install python packages with pip from requirements-pip.txt
#ONBUILD COPY requirements-pip.txt /home/jovyan/work
#ONBUILD RUN pip install --no-cache-dir -r requirements-pip.txt

# Deploy application code
#ONBUILD COPY . /home/$NB_USER/work

# Install H2O pysparkling requirements
RUN pip install requests && \
    pip install tabulate && \
    pip install six && \
    pip install future && \
    pip install colorama

# Expose H2O Flow UI ports
EXPOSE 54321
EXPOSE 54322
EXPOSE 55555

USER root
RUN \
    cd /home/$NB_USER \
    && wget -q http://h2o-release.s3.amazonaws.com/h2o/rel-wolpert/11/h2o-3.18.0.11.zip \
    && unzip h2o-3.18.0.11.zip \
    && cd h2o-3.18.0.11 \
    && mkdir -p /usr/local/h2o_jar/ \
    && cp h2o.jar /usr/local/h2o_jar/ \
    && cd .. \
    && rm -rf h2o-3.18.0.11*

# The following command removes the H2O module for Python.
RUN pip uninstall h2o || true && pip install http://h2o-release.s3.amazonaws.com/h2o/rel-wolpert/11/Python/h2o-3.18.0.11-py2.py3-none-any.whl

#https://s3.amazonaws.com/h2o-release/sparkling-water/rel-2.3/5/sparkling-water-2.3.5.zip
# Install H2O sparkling water
RUN \
    cd /home/$NB_USER && \
    wget https://s3.amazonaws.com/h2o-release/sparkling-water/rel-2.3/5/sparkling-water-2.3.5.zip && \
    unzip sparkling-water-2.3.5.zip && \
    cd sparkling-water-2.3.5 && \
    cp -R bin/* /usr/local/bin && \
    cd .. && \
    rm -rf sparkling-water-2.3.5* 

# Add sparkling-water's /bin folder to path
#ENV PATH="/home/$NB_USER/sparkling-water-2.3.5/bin:${PATH}"

RUN pip install h2o_pysparkling_2.3 

# Switch back to jovyan to avoid container running accidentally as root
#USER $NB_USER


USER root

# Julia dependencies
# install Julia packages in /opt/julia instead of $HOME
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=0.6.2

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    echo "dc6ec0b13551ce78083a5849268b20684421d46a7ec46b17ec1fab88a5078580 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

# Show Julia where conda libraries are \
RUN mkdir /etc/julia && \
    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
    # Create JULIA_PKGDIR \
    mkdir $JULIA_PKGDIR && \
    chown $NB_USER $JULIA_PKGDIR && \
    fix-permissions $JULIA_PKGDIR


USER $NB_UID

# R packages
# R packages including IRKernel which gets installed globally.
RUN conda install --quiet --yes \
    'rpy2=2.8*' \
    'r-base=3.4.1' \
    'r-irkernel=0.8*' \
    'r-plyr=1.8*' \
    'r-devtools=1.13*' \
    'r-tidyverse=1.1*' \
    'r-shiny=1.0*' \
    'r-rmarkdown=1.8*' \
    'r-forecast=8.2*' \
    'r-rsqlite=2.0*' \
    'r-reshape2=1.4*' \
    'r-nycflights13=0.2*' \
    'r-caret=6.0*' \
    'r-rcurl=1.95*' \
    'r-crayon=1.3*' \
    'r-randomforest=4.6*' \
    'r-htmltools=0.3*' \
    'r-sparklyr=0.7*' \
    'r-htmlwidgets=1.0*' \
    'r-hexbin=1.27*' && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER


# Add Julia packages. Only add HDF5 if this is not a test-only build since
# it takes roughly half the entire build time of all of the images on Travis
# to add this one package and often causes Travis to timeout.
#
# Install IJulia as jovyan and then move the kernelspec out
# to the system share location. Avoids problems with runtime UID change not
# taking effect properly on the .local folder in the jovyan home dir.
USER root
RUN apt-get install -y hdf5-tools
USER $NB_UID

RUN julia -e 'Pkg.init()' && \
    julia -e 'Pkg.update()' && \
    (test $TEST_ONLY_BUILD || julia -e 'Pkg.add("HDF5")') && \
    julia -e 'Pkg.add("Gadfly")' && \
    julia -e 'Pkg.add("PyCall")' && \
    julia -e 'Pkg.add("RCall")' && \
    julia -e 'Pkg.add("CxxWrap.jl")' && \
    julia -e 'Pkg.add("JavaCall.jl")' && \
    julia -e 'Pkg.add("RDatasets")' && \
    julia -e 'Pkg.add("IJulia")' && \
    # Precompile Julia packages \
    julia -e 'using IJulia' && \
    # move kernelspec out of home \
    mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
    rm -rf $HOME/.local && \
    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter 


    # Install Tensorflow
RUN conda install --quiet --yes \
    'tensorflow=1.5*' \
    'keras=2.1*' && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER


USER root
# INSTALL THEANOS
RUN apt-get update && apt-get install -y \
  build-essential \
  gfortran \
  git \
  wget \
  liblapack-dev \
  libopenblas-dev \
  python-dev \
  python-pip \
  python-nose \
  python-numpy \
  python-scipy \
  vim 

# Install bleeding-edge Theano
RUN pip install --upgrade pip && \
    pip install --upgrade six && \
    pip install --upgrade --no-deps git+git://github.com/Theano/Theano.git

# Install gcc xgboost
RUN pip install xgboost

USER root
RUN pip install py4j==0.10.6 psutil
RUN pip install sos
RUN pip install sos-notebook
RUN python -m sos_notebook.install
RUN pip install bash_kernel
RUN python -m bash_kernel.install

RUN pip install markdown-kernel  
#USER root
USER $NB_UID
#python custom
# ENV CUSTOM_DIR="$HOME/.custom"

# VOLUME $CUSTOM_DIR
# RUN mkdir $CUSTOM_DIR
#ENV PIPI=$PIP_TARGET
# ENV PIPO_TARGET=$CUSTOM_DIR/python
# RUN mkdir $PIPO_TARGET


#r custom
RUN echo 'options(repos = c(CRAN = "https://cran.rstudio.com"))' >/home/$NB_USER/.Rprofile
# RUN mkdir $CUSTOM_DIR/R
RUN Rscript -e "install.packages('h2o')"
RUN Rscript -e "install.packages('sparklyr')"
RUN Rscript -e "install.packages('rsparkling')"

#julia custom
# RUN mkdir -p $CUSTOM_DIR/julia
#RUN ln -s $CUSTOM_DIR/julia/v0.6/REQUIRE $JULIA_PKGDIR/v0.6 

# ENV JULIA_LOAD_PATH=$JULIA_PKGDIR/v0.6
ENV PYSPARK_PYTHON='$CONDA_DIR/bin/python'
# RUN julia -e 'Pkg.init()'

#ENV NB_USER=mlds
ENV NB_USER_CUSTOM=mlds
USER root
#RUN start.sh true 
RUN echo $NB_USER:$NB_USER_CUSTOM | chpasswd
RUN usermod -a -G sudo $NB_USER
RUN ln -s /home/$NB_USER /home/$NB_USER_CUSTOM

# COPY $NB_USER_CUSTOM.sh /usr/local/bin
RUN conda install -c conda-forge jupyter_nbextensions_configurator
RUN cp /etc/sudoers /root/sudoers.bak
RUN echo "$NB_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo 'alias _sudo="/usr/bin/sudo"' >> /home/$NB_USER/.bashrc
RUN echo 'alias sudo="sudo -s PATH=\$PATH"' >> /home/$NB_USER/.bashrc

EXPOSE 7077 8000-9080 4040 7001-7006 54321-54331 4040-4050 6066 6006 3000-3010 5050 5051 45454 8042 10200  19888 21000-24000 30000-34000 
USER $NB_UID
ENV PYSPARK_PYTHON="$CONDA_DIR/bin/python"
#USER root
#RUN mv /usr/local/bin /usr/local/bin_base
#RUN ln -s /usr/local/bin $CUSTOM_DIR/bin
# RUN mkdir -p $CUSTOM_DIR/bin 
# RUN rm -rf /usr/local/bin/$NB_USER_CUSTOM.sh

USER root

# RUN mkdir -p /srv/deb/var/lib /usr/local/bin_base && cp -R /var/lib/dpkg /srv/deb/var/lib
# RUN mkdir -p /srv/tmp
USER $NB_UID
# COPY cmd/apt-get /usr/local/bin_base/
# RUN sudo chmod -R 777 /usr/local/bin_base/
# RUN sudo chown $NB_USER:users /usr/local/bin_base/apt-get
# RUN chmod -R 777 ~/.custom/
# RUN mkdir ~/.customs/
# RUN mkdir ~/.tmp/
# ENV CUSTOM_DIR="$HOME/.customs"
# ENV R_LIBS_USER=$CUSTOM_DIR/R:$R_LIBS_USER
# ENV JULIA_PKGDIR=$CUSTOM_DIR/julia
# ENV PIPO_TARGET=$CUSTOM_DIR/python
# ENV PYTHONUSERBASE=$PIPO_TARGET
# ENV PYTHONPATH=$PIPO_TARGET:$PYTHONPATH
ENV PATH="/home/$NB_USER/sparkling-water-2.3.5/bin:${PATH}"
# RUN echo 'alias _apt-get="/usr/bin/apt-get"' >> /home/$NB_USER/.bashrc
RUN echo "stty rows 24" >> /home/$NB_USER/.bashrc
RUN echo "stty cols 100" >> /home/$NB_USER/.bashrc


# ENV PYTHON="$PYTHONUSERBASE" 
RUN pip install rpy2
ENV R_HOME="$CONDA_DIR/lib/R"
ENV PATH=/usr/lib/rstudio-server/bin:$PATH

USER root
RUN conda install -c r r-essentials r-base
RUN apt-get -yqf install && apt-get update && apt-get install -yq --no-install-recommends libreadline-dev && pip install rpy2 --upgrade
RUN apt-get install -y r-base r-base-dev libjpeg62


## Download and install RStudio server & dependencies
## Attempts to get detect latest version, otherwise falls back to version given in $VER
## Symlink pandoc, pandoc-citeproc so they are available system-wide
RUN curl -sL http://freefr.dl.sourceforge.net/project/libpng/zlib/1.2.9/zlib-1.2.9.tar.gz --output zlib-1.2.9.tar.gz \
    && tar xzf zlib-1.2.9.tar.gz \
    && cd zlib-1.2.9 \
    && ./configure &&  make && make install \
    && cd /lib/x86_64-linux-gnu \
    && ln -s -f /usr/local/lib/libz.so.1.2.9/lib libz.so.1 \
    && cd - \
    && rm -rf zlib-1.2.9
RUN apt-get install -y  gdebi-core 
 RUN   wget https://download2.rstudio.org/rstudio-server-1.1.453-amd64.deb  
 RUN   gdebi --non-interactive  rstudio-server-1.1.453-amd64.deb
RUN echo "server-app-armor-enabled=0" >> /etc/rstudio/rserver.conf 
# RUN apt-get install -y  --no-install-recommends gdebi-core && \
#     wget https://download2.rstudio.org/rstudio-server-1.1.453-amd64.deb  && \
#     gdebi --non-interactive rstudio-server-1.1.453-amd64.deb  || ( apt-get -f -y install  && gdebi --non-interactive rstudio-server-1.1.453-amd64.deb )
RUN apt-get update \
  && apt-get -f install \
  && apt-get install -y --no-install-recommends \
    file \
    git \
    libapparmor1 \
    libcurl4-openssl-dev \
    libedit2 \
    libssl-dev \
    lsb-release \
    psmisc \
    python-setuptools \
    sudo \
    wget
# RUN apt-get install -y gdebi-core || apt-get -f install && apt-get install -y gdebi-core

RUN \
# wget -O libssl1.0.0.deb http://ftp.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u7_amd64.deb \
  # && dpkg -i libssl1.0.0.deb \
  # && rm libssl1.0.0.deb \
  RSTUDIO_LATEST=$(wget --no-check-certificate -qO- https://s3.amazonaws.com/rstudio-server/current.ver) \
  && [ -z "$RSTUDIO_VERSION" ] && RSTUDIO_VERSION=$RSTUDIO_LATEST || true \
  # && wget https://download2.rstudio.org/rstudio-server-1.1.453-amd64.deb 
  # && dpkg -i rstudio-server-${RSTUDIO_VERSION}-amd64.deb \
# RUN wget https://download2.rstudio.org/rstudio-server-1.1.453-amd64.deb  && apt-get -f -y install  && gdebi --non-interactive rstudio-server-1.1.453-amd64.deb || \
#   ## Symlink pandoc & standard pandoc templates for use system-wide
# RUN   ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin \
#   && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin \
#   && git clone https://github.com/jgm/pandoc-templates \
#   && mkdir -p /opt/pandoc/templates \
#   && cp -r pandoc-templates*/* /opt/pandoc/templates && rm -rf pandoc-templates* \
#   && mkdir /root/.pandoc && ln -s /opt/pandoc/templates /root/.pandoc/templates \
#   && apt-get clean \
#   && rm -rf /var/lib/apt/lists/ \
#   ## RStudio wants an /etc/R, will populate from $R_HOME/etc
    mkdir -p /etc/R \
  ## Write config files in $R_HOME/etc
  && echo '\n\
    \n# Configure httr to perform out-of-band authentication if HTTR_LOCALHOST \
    \n# is not set since a redirect to localhost may not work depending upon \
    \n# where this Docker container is running. \
    \nif(is.na(Sys.getenv("HTTR_LOCALHOST", unset=NA))) { \
    \n  options(httr_oob_default = TRUE) \
    \n}' >> $R_HOME/etc/Rprofile.site \
#   && echo "PATH=${PATH}" >> $R_HOME/etc/Renviron \
#   ## Need to configure non-root user for RStudio
#   ## Prevent rstudio from deciding to use /usr/bin/R if a user apt-get installs a package
&&  echo "rsession-which-r=$CONDA_DIR/bin/R" >> /etc/rstudio/rserver.conf && echo "PATH=${PATH}" >> $R_HOME/etc/Renviron
#   ## use more robust file locking to avoid errors when using shared volumes:
#   && echo 'lock-type=advisory' >> /etc/rstudio/file-locks \ 
#   ## configure git not to request password each time 
#   && git config --system credential.helper 'cache --timeout=3600' \
#   && git config --system push.default simple \
#   ## Set up S6 init system
#   && wget -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/v1.11.0.1/s6-overlay-amd64.tar.gz \
#   && tar xzf /tmp/s6-overlay-amd64.tar.gz -C / \
#   && mkdir -p /etc/services.d/rstudio \
#   && echo '#!/usr/bin/with-contenv bash \
#           \n exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0' \
#           > /etc/services.d/rstudio/run \
#   && echo '#!/bin/bash \
#           \n rstudio-server stop' \
#           > /etc/services.d/rstudio/finish \ 
#   && mkdir -p $HOME/.rstudio/monitored/user-settings \ 
#   && echo 'alwaysSaveHistory="0" \ 
#           \nloadRData="0" \
#           \nsaveAction="0"' \ 
#           > $HOME/.rstudio/monitored/user-settings/user-settings  
#   # && chown -R rstudio:rstudio $HOME/.rstudio


# RUN chown -R jovyan:users $HOME/.rstudio
# RUN sed -ir "s/stty rows/stty rows 24/" $HOME/.bashrc && sed -ir "s/stty cols/stty cols 100/" $HOME/.bashrc
# RUN echo "stty cols $COLUMNS" >> /home/$NB_USER/.bashrc
# EX8787POSE 

## automatically link a shared volume for kitematic users
# VOLUME /home/rstudio/kitematic
RUN mkdir -p  $HOME/.rstudio/monitored/user-settings
RUN bash -c 'cp /usr/lib/rstudio-server/www/templates/encrypted-sign-in.htm{,.old}' && rm -rf /usr/lib/rstudio-server/www/templates/encrypted-sign-in.htm
COPY todo_Rstudio/encrypted-sign-in.htm /usr/lib/rstudio-server/www/templates/
RUN echo "R_LIBS_USER=${R_LIBS_USER}" >> $R_HOME/etc/Renviron
RUN echo "initialWorkingDirectory=~/work">> $HOME/.rstudio/monitored/user-settings/user-settings

COPY todo_Rstudio/userconf.sh /etc/cont-init.d/userconf

# ## running with "-e ADD=shiny" adds shiny server
COPY todo_Rstudio/add_shiny.sh /etc/cont-init.d/add

COPY todo_Rstudio/pam-helper.sh /usr/lib/rstudio-server/bin/pam-helper
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
  libxml2-dev \
  libcairo2-dev \
  libsqlite3-dev \
  libmariadbd-dev \
  libmariadb-client-lgpl-dev \
  libpq-dev \
  libssh2-1-dev \
  unixodbc-dev 

RUN  R -e "source('https://bioconductor.org/biocLite.R')" \
   && Rscript -e "install.packages(c('littler', 'docopt','tidyverse','dplyr','ggplot2','devtools','formatR','remotes','selectr','caTools'))"
RUN jupyter labextension install jupyterlab-sos

# RUN mkdir -p /opt/conda/lib/python3.6/site-packages/infix-1.2 && pip install inrex 
COPY infix-1.2/in* /opt/conda/lib/python3.6/site-packages/
RUN pip install dfply plotnine && conda install numba --quiet --yes

COPY $NB_USER_CUSTOM.sh /usr/local/bin
USER $NB_USER
# RUN python /opt/conda/lib/python3.6/site-packages/infix-1.2/setup.py install 
USER root
COPY $NB_USER_CUSTOM.sh /usr/local/bin
RUN chmod a+x /usr/local/bin/$NB_USER_CUSTOM.sh
RUN rm -rf $HOME/work/*
RUN chown -R jovyan:users $HOME/.rstudio
CMD ["mlds.sh"]
