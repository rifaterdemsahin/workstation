FROM nvidia/cuda:9.0-devel-ubuntu16.04 as buildagent

# Langugage fix in dockerfile
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# dns fix in dockerfile
RUN echo "nameserver 8.8.8.8" > /etc/resolve.conf

# #Install tensorflow based as tensor is the focus to run

#Basic operating system prep for the build agent and pycuda and custome libraries
RUN apt-get update
RUN apt install software-properties-common -y
RUN apt-get install aptitude -y
RUN aptitude -f install libcurl4-openssl-dev -y

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    curl \
    bash \
    unzip \
    jq \
    git \
    iputils-ping \
    libunwind8 \
    netcat \
    software-properties-common \
    libssl1.0 \
  && rm -rf /var/lib/apt/lists/*

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

# based files
COPY ./config.sh .
COPY ./run.sh .
COPY ./start.sh .
RUN chmod +x config.sh
RUN chmod +x run.sh
RUN chmod +x start.sh
#Azure DevOps Agent Setup Complete"

# #Workload Setup Started" 
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

# Single Liner to have less layers
RUN apt-get update && apt-get install -y -q --no-install-recommends \
     apt-utils \
     dialog \
     build-essential \
     wget  \
     apt-transport-https \
     powershell \
     curl \
     moby-engine \
     seyon \
     freeglut3-dev \
     libxi-dev \
     libxmu-dev \
     libgl1-mesa-dev \
     libboost-all-dev \
     libboost-thread-dev \ 
   && rm -rf /var/lib/apt/lists/*

#Explicit repo errors
RUN apt-get update && apt-get install build-essential && apt-get install -y \
        libqt5opengl5 

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get install -y -q keyboard-configuration 
RUN apt-get install --reinstall -y locales
RUN sed -i 's/# pl_PL.UTF-8 UTF-8/pl_PL.UTF-8 UTF-8/' /etc/locale.gen
# # generate chosen locale
RUN locale-gen pl_PL.UTF-8
ENV LANG pl_PL.UTF-8
ENV LANGUAGE pl_PL
ENV LC_ALL pl_PL.UTF-8

#dot net manual install started
RUN wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb
RUN apt-get update
RUN apt-get install -y apt-transport-https 
RUN apt-get update
RUN apt-get install -y dotnet-sdk-6.0

RUN apt-get update && apt-get install -y --no-install-recommends \
      binutils \
      gdb \
      freeglut3 \
      freeglut3-dev 

RUN apt-get update && apt-get install -y -q --no-install-recommends python3.7

RUN apt-get install -y -q python*-distutils

RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3.7 get-pip.py

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y python-setuptools
RUN apt-get install software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update && apt-get install -y -q python3.7-dev libffi-dev libssl-dev
# Base for our requirements
RUN apt-get update && apt-get install -y -q libpng12-dev libfreetype6-dev --fix-missing


COPY ./requirements.txt .

# after the merge it stopped working compare with devel merge
# RUN apt-get update && apt-get install -y -q libgtk-3-dev --fix-missing
RUN apt-get update && apt-get install -y -q tox libboost-all-dev --fix-missing
RUN apt-get update && apt-get install -y -q build-essential cmake --fix-missing
RUN apt-get update && apt-get install -y -q cmake --fix-missing
RUN apt-get update && apt-get install -y -q libxml2-dev --fix-missing
RUN apt-get update && apt-get install -y -q libxmlsec1-dev --fix-missing

RUN python3.7 -m pip install --upgrade pip setuptools p5py pep517 distlib poetry
# Could not build wheels for pycuda, which is required to install pyproject.toml-based projects
# RUN python3.7 -m pip install --upgrade matplotlib==2.1.1
RUN python3.7 -m pip install --upgrade --user --requirement requirements.txt

# https://www.tensorflow.org/install/pip#system-install
RUN apt install -y python3.7-dev python3-pip python3.7-venv

# RUN python3.7 -m pip install cudatoolkit==9.0

# RUN python3.7 -m pip install cuda-python==9.0
# RUN python3.7 -m pip install pycuda
# RUN apt-get install nvidia-cuda-toolkit
# Cuda image is used this part is not needed
# RUN apt-get install -y cuda-9.0
RUN python3.7 -m pip -vvv install stardist

# Dev Toolset
RUN apt-get update
RUN apt-get install python3.7-dev -y
RUN apt-get install python3-pip -y
RUN apt-get install libssl-dev -y
RUN apt-get install build-essential -y
RUN apt-get install libffi-dev -y
RUN apt-get install libsnappy-dev -y
RUN apt-get install lib32ncurses5-dev -y
RUN apt-get install libpcap-dev  -y
RUN apt-get install libpq-dev -y

RUN apt install -y build-essential

#Prep for pycuda enviroment
RUN python3.7 -m pip install --upgrade pip
RUN python3.7 -m pip install wheel setuptools numpy-quaternion numba 
RUN apt-get install build-essential autoconf libtool pkg-config python-opengl python-pil python-pyrex python-pyside.qtopengl idle-python2.7 qt4-dev-tools qt4-designer libqtgui4 libqtcore4 libqt4-xml libqt4-test libqt4-script libqt4-network libqt4-dbus python-qt4 python-qt4-gl libgle3 python-dev libssl-dev  -y

RUN python3.7 -m pip install numpy==1.19.5
RUN echo "import numpy as np" >> numpytester.py
