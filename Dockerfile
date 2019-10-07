#
# Darknet
#

# Ubuntu 18.04 + CUDA 10.1
FROM nvidia/cuda:10.1-devel-ubuntu18.04
ARG DEBIAN_FRONTEND=noninteractive

# Install base system
WORKDIR /
RUN apt-get -qq -y update && apt-get -qq -y dist-upgrade
RUN apt-get -qq -y update && apt-get -qq -y install \
	build-essential \
	git \
    cmake \
    python3 \
    python3-pip \
    python3-numpy \
    libtbb2 \
    libtbb-dev \
    libcudnn7-dev \
    wget \
    libopencv-dev \
    python3-opencv \
    && apt-get clean
RUN rm -rf /var/lib/apt/lists/*
ENV LD_LIBRARY_PATH="/usr/local/cuda/compat:${LD_LIBRARY_PATH}"

# Install Darknet with CUDA, CUDNN and OpenCV
WORKDIR /opt
ENV GPU=1
ENV CUDNN=1
ENV OPENCV=1
ENV LIBSO=1
RUN git clone https://github.com/AlexeyAB/darknet.git
WORKDIR /opt/darknet
COPY patches/Makefile.patch /opt/darknet
RUN patch Makefile Makefile.patch
RUN make -e -j
RUN cp libdarknet.so /usr/local/lib && ldconfig
RUN cp darknet /usr/local/bin
COPY patches/darknet_py.patch /opt/darknet
RUN patch darknet.py darknet_py.patch
RUN mkdir /usr/local/share/darknet
RUN cp darknet.py /usr/local/share/darknet
ENV PYTHONPATH="/usr/local/share/darknet:${PYTHONPATH}"
WORKDIR /opt
RUN rm -rf darknet

# Final state
WORKDIR /