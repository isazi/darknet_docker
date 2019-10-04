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
    libeigen3-dev \
    libgtk2.0-dev \
    pkg-config \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libavresample-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libdc1394-22-dev \
    libv4l-dev \
    ffmpeg \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    wget \
    && apt-get clean
RUN rm -rf /var/lib/apt/lists/*
ENV LD_LIBRARY_PATH="/usr/local/cuda/compat:${LD_LIBRARY_PATH}"

# Install OpenCV with CUDA
WORKDIR /opt
RUN wget -q -O opencv.tar.gz https://github.com/opencv/opencv/archive/3.4.7.tar.gz
RUN tar xzvf opencv.tar.gz && rm opencv.tar.gz
RUN wget -q -O opencv_contrib.tar.gz https://github.com/opencv/opencv_contrib/archive/3.4.7.tar.gz
RUN tar xzvf opencv_contrib.tar.gz && rm opencv_contrib.tar.gz
WORKDIR /opt/opencv-3.4.7/build
RUN cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_CUDA=ON -D INSTALL_C_EXAMPLES=OFF \
    -D ENABLE_FAST_MATH=1 -D CUDA_FAST_MATH=1 -D WITH_CUBLAS=1 -D WITH_FFMPEG=ON -D WITH_GSTREAMER=ON -D ENABLE_PRECOMPILED_HEADERS=OFF \
    -D INSTALL_PYTHON_EXAMPLES=OFF -D OPENCV_EXTRA_MODULES_PATH=/opt/opencv_contrib-3.4.7/modules -D BUILD_EXAMPLES=OFF ..
RUN make -j 2
RUN make install
RUN rm -rf /opt/opencv_contrib-3.4.7 && rm -rf /opt/opencv-3.4.7

# Install Darknet with CUDA, CUDNN and OpenCV
WORKDIR /opt
ENV GPU=1
ENV CUDNN=1
ENV OPENCV=1
ENV OPENMP=1
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