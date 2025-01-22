FROM nvidia/cuda:9.0-devel-ubuntu16.04 as buildagent

# Langugage set
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get clean && apt-get update && apt-get install -y locales && \
    sed -i -e "s/# $LANG.*/$LANG UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=$LANG


# Dns set
RUN echo "nameserver 8.8.8.8" > /etc/resolve.conf

# Base ToolSet for DevOps Agent
RUN apt-get update && apt-get install -y --no-install-recommends \
ca-certificates \
wget \
curl \
bash \
unzip \
software-properties-common \
jq \
git \
iputils-ping \
libunwind8 \
netcat \
libssl1.0 \
keyboard-configuration \
git

# Repos set after software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN apt-get update
RUN add-apt-repository universe

RUN curl -LsS https://aka.ms/InstallAzureCLIDeb | bash \
  && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH=amd64
ARG AGENT_VERSION=2.185.1

WORKDIR /azp
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      AZP_AGENTPACKAGE_URL=https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz; \
    else \
      AZP_AGENTPACKAGE_URL=https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-${TARGETARCH}-${AGENT_VERSION}.tar.gz; \
    fi; \
    curl -LsS "$AZP_AGENTPACKAGE_URL" | tar -xz

# base files for build agent
COPY ./config.sh .
COPY ./run.sh .
COPY ./start.sh .
RUN chmod +x config.sh
RUN chmod +x run.sh
RUN chmod +x start.sh
# Azure DevOps Agent Setup Complete"

# Generic Tools
RUN apt install -y 

RUN apt-get update && apt-get install -y -q --no-install-recommends \
     apt-utils \
     dialog \
     build-essential \
     apt-transport-https \
     powershell \
     moby-engine \
     seyon \
     freeglut3-dev \
     libxi-dev \
     libxmu-dev \
     libgl1-mesa-dev \
     libboost-all-dev \
     libqt5opengl5 \
     libboost-thread-dev 

#Dot net related
RUN wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb
RUN apt-get update && apt-get install -y -q --no-install-recommends \
apt-transport-https \ 
dotnet-sdk-6.0

#Python prerequsite related
RUN apt-get update && apt-get install -y --no-install-recommends \
binutils \
gdb \
freeglut3 \
freeglut3-dev

#Python 
RUN apt-get update && apt-get install -y -q --no-install-recommends python3.7 \
python*-distutils \
python-setuptools

#Python Pip
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3.7 get-pip.py
RUN python3.7 -m pip install --upgrade pip setuptools \
p5py \
pep517 \
distlib \
poetry

#Python Dev
RUN apt-get update && apt-get install -y -q --fix-missing -vvv python3.7-dev \
libffi-dev \
libssl-dev \
libpng12-dev \
libfreetype6-dev \ 
libgtk-3-dev \
tox \ 
libboost-all-dev \
build-essential \ 
cmake \ 
libxml2-dev \
libxmlsec1-dev \
stardist \
python3-tk \
python3.7-venv \
python3.7-dev \
python3-pip \
libssl-dev \
build-essential \
libffi-dev \
libsnappy-dev \
lib32ncurses5-dev \
libpcap-dev \
libpq-dev \
python-dev

# Apt for PyCuda based libraries
RUN apt-get update  && apt-get install -vvv -y build-essential \
autoconf \
libtool \
pkg-config \
python-opengl \
python-pil \
python-pyrex \
python-pyside.qtopengl \
idle-python2.7 \
qt4-dev-tools \
qt4-designer \
libqtgui4 \
libqtcore4 \
libqt4-xml \
libqt4-test \
libqt4-script \
libqt4-network \
libqt4-dbus \
python-qt4 \
python-qt4-gl \
libxslt1-dev \
libgle3 \
libcurl4-openssl-dev 

#Pycuda prep pip
RUN python3.7 -m pip install --upgrade pip
RUN python3.7 -m pip install wheel \
setuptools \
numpy-quaternion \
numba

#Numpy Prep
RUN python3.7 -m pip install https://files.pythonhosted.org/packages/21/2d/cb1cbb484a6e8738a338bf5fb14b6103ddd1956416aeccaf2edd11587b86/mako_render-0.1.0-py3-none-any.whl
RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y
RUN apt-get update -y
RUN apt-get install gcc-6 g++-6 -y

#Anaconda install for PyCuda
# Install conda
RUN apt-get -qq update && apt-get -qq -y install curl bzip2 \
    && curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -bfp /usr/local \
    && rm -rf /tmp/miniconda.sh \
    && conda install -y python=3.7 \
    && conda update  conda \
    && apt-get -qq -y remove curl bzip2 \
    && apt-get -qq -y autoremove \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log /tmp/* /var/tmp/* \
    && conda clean --all --yes \
    && conda config --add channels defaults \
    && conda config --add channels bioconda \
    && conda config --add channels conda-forge

# Install mamba
RUN conda install -y mamba=0.19.1 && mamba clean --all --yes

# Install dependencies
RUN mamba install -y snakemake=5.20.1 fastqc=0.11.9 \
    bowtie2=2.4.2 samtools=1.11 \
    bwa=0.7.17 pysam=0.16.0.1 \
    pandas=1.1.3 numpy=1.19.2 \
    lxml=4.6.1 \
    && mamba clean --all --yes

RUN conda config --add channels conda-forge
RUN conda config --set channel_priority strict
RUN conda install pycuda

#Python3.7 based downgrades for the cuda:9.0
RUN echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list
RUN apt-get update && apt-get install -y libnccl2=2.0.5-3+cuda9.0 libnccl-dev=2.0.5-3+cuda9.0 -y --allow-downgrades

#Cuda:9.0 Path settings
RUN export CUDA_ROOT=/usr/local/cuda-9.0/bin
RUN export CUDA_INC_DIR=/usr/local/cuda-9.0/include
RUN export CPATH=$PATH:/usr/local/cuda-9/targets/x86_64-Linux/include
RUN export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/cuda-9/targets/x86_64-Linux/lib
RUN export PATH=$PATH:/usr/local/cuda-9.0/bin
RUN echo "export PATH=/usr/local/cuda-9.0/bin:$PATH" >> /etc/profile.d/cuda.sh

#PyCuda Install
RUN python3.7 -m pip install pycuda==2017.1.1 --no-cache-dir --user

# Customer Library Apt Dependecy install
RUN apt-get update  && apt-get install -vvv -y libtiff5-dev \ 
libjpeg8-dev \
libopenjp2-7-dev \
zlib1g-dev \
libfreetype6-dev \
liblcms2-dev \
libwebp-dev \
tcl8.6-dev \
tk8.6-dev \
python3-tk \
libharfbuzz-dev \
libfribidi-dev \
libxcb1-dev 

# Customer Library Pip Dependecy install
RUN python3.7 -m pip install --upgrade \
setuptools \
wheel \
scipy==1.4.1 \
tox \
keyring \
imageio==2.8.0 \
open3d \
tqdm==4.46.0 \
trimesh==3.9.1 \
astroid==2.4.2 \
atomicwrites==1.4.0 \
attrs==20.2.0 \
colorama==0.4.3 \
colorlog==4.1.0 \
cycler==0.10.0 \
doxypypy==0.8.8.6 \
enum34==1.1.10 \
importlib-metadata==2.0.0 \
lazy-object-proxy==1.4.3 \
matplotlib==2.1.1 \
mccabe==0.6.1 \
Nuitka==0.6.5 \
numpy==1.19.5 \
packaging==20.4 \
pluggy==0.13.1 \
plyfile==0.7.1 \
py==1.9.0 \
PyGLM==0.4.5b1 \
PyOpenGL==3.1.0 \
pyparsing==2.4.7 \
pytest==5.0.1 \
python-dateutil==2.8.1 \
pytz==2020.1 \
pyueye==4.90.0.0 \
six==1.15.0 \
toml==0.10.1 \
transforms3d==0.3.1 \
typed-ast==1.4.1 \
vtk \
wcwidth==0.2.5 \
wrapt==1.12.1 \
zipp \
pylint==2.6.0 \
pylint-runner==0.6.0 \
pandas \
more-itertools==8.5.0 \
scikit-image \
numpy \
numpy-quaternion \
artifacts-keyring \
pyglut==1.0.0 \
openmesh==1.1.2 \
typeguard \
isort \
virtualenv \
twine \
keyring \ 
artifacts-keyring \ 
azure-storage-blob \ 
azure-storage-file-share \
imageio==2.9.0 \
six==1.16.0 \
pydantic==1.8.1 \
pytest==6.2.3 \
iniconfig==1.1.1 \
requests==2.25.1 \
matplotlib==3.3.4 \
pycparser==2.20 \ 
typing-extensions==3.10.0.0 \
imageio==2.9.0 \
matplotlib==3.3.4 \
numpy==1.19.5 \
pydantic==1.8.1 \
pillow==8.2.0 \
opencv-contrib-python==4.4.0.44.post2 \
pyueye==4.90.0.0 \
requests==2.25.1 \
zipp==3.4.1 \
py==1.10.0 \
colorlog==5.0.1 \
importlib-metadata==4.4.0 \
attrs==21.2.0 \
pillow==8.2.0
