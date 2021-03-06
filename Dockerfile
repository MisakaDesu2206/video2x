FROM ubuntu:19.10
#FROM nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04
MAINTAINER Danielle Douglas <ddouglas87@gmail.com>
MAINTAINER Lhanjian <lhjay1@foxmail.com>
MAINTAINER K4YT3X <k4yt3x@k4yt3x.com>

# Don't ask questions during image setup.
ENV DEBIAN_FRONTEND noninteractive
ENV NASM_VERSION 2.14
ENV NVCODEC_VERSION 8.2.15.6
ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig
ENV FFMPEG_VERSION 4.1.2

# Install apt-fast, because we got gigs to download.
RUN apt-get update && apt-get install -y apt-utils &&\
    apt-get install -y --no-install-recommends software-properties-common &&\
    add-apt-repository ppa:apt-fast/stable &&\
    add-apt-repository -y ppa:graphics-drivers/ppa &&\
    apt-get install -y --no-install-recommends apt-fast && apt-fast update


## Install Video2X ##

# Dependencies
RUN apt-fast install -y --no-install-recommends git-core python3-pip python3-setuptools python3-wheel python3-psutil ffmpeg gcc g++ \
    libc6-dev python3-dev libmagic-dev libmagic1 python3.8 nvidia-driver-440 nvidia-cuda-toolkit gnupg2 curl ca-certificates pkg-config \
    autoconf libx264-dev libx265-dev libnuma-dev libvpx-dev libfdk-aac-dev libmp3lame-dev libopus-dev libass-dev libfreetype6-dev libgnutls28-dev \
    libsdl2-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev texinfo wget yasm zlib1g-dev \
    libass-dev libfreetype6-dev libsdl2-dev p11-kit libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev \
    pkg-config texinfo wget zlib1g-dev libchromaprint-dev frei0r-plugins-dev gnutls-dev ladspa-sdk libcaca-dev libcdio-paranoia-dev libcodec2-dev \
    libfontconfig1-dev libfreetype6-dev libfribidi-dev libgme-dev libgsm1-dev libjack-dev libmodplug-dev libmp3lame-dev libopencore-amrnb-dev \
    libopencore-amrwb-dev libopenjp2-7-dev libopenmpt-dev libopus-dev libpulse-dev librsvg2-dev librubberband-dev librtmp-dev libshine-dev \
    libsmbclient-dev libsnappy-dev libsoxr-dev libspeex-dev libssh-dev libtesseract-dev libtheora-dev libtwolame-dev libv4l-dev libvo-amrwbenc-dev \
    libvorbis-dev libvpx-dev libwavpack-dev libwebp-dev libx264-dev libx265-dev libxvidcore-dev libxml2-dev libzmq3-dev libzvbi-dev liblilv-dev \
    libopenal-dev opencl-dev libjack-dev libbluray-dev libfdk-aac-dev libmysofa-dev

RUN curl -vfsSLO https://www.nasm.us/pub/nasm/releasebuilds/$NASM_VERSION/nasm-$NASM_VERSION.tar.bz2 \
    && tar -xjf nasm-$NASM_VERSION.tar.bz2 \
    && cd nasm-$NASM_VERSION \
    && ./autogen.sh \
    && ./configure \
    && make -j$(nproc) \
    && make install

RUN git clone --recurse-submodules -b n$NVCODEC_VERSION --depth 1 https://git.videolan.org/git/ffmpeg/nv-codec-headers \
    && cd nv-codec-headers \
    && make install

RUN curl -vfsSLO https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2 \
    && tar -xjf ffmpeg-$FFMPEG_VERSION.tar.bz2 \
    && cd ffmpeg-$FFMPEG_VERSION \
    && ./configure --enable-cuda-sdk --enable-cuvid --enable-nonfree --enable-libnpp --enable-nvenc \
    --enable-gpl --enable-version3 \
    --enable-small --enable-avisynth --enable-chromaprint \
    --enable-frei0r --enable-gmp --enable-gnutls --enable-ladspa \
    --enable-libass --enable-libcaca --enable-libcdio \
    --enable-libcodec2 --enable-libfontconfig --enable-libfreetype \
    --enable-libfribidi --enable-libgme --enable-libgsm --enable-libjack \
    --enable-libmodplug --enable-libmp3lame --enable-libopencore-amrnb \
    --enable-libopencore-amrwb --enable-libopencore-amrwb \
    --enable-libopenjpeg --enable-libopenmpt --enable-libopus --enable-libpulse \
    --enable-librsvg --enable-librubberband --enable-librtmp --enable-libshine \
    --enable-libsnappy --enable-libsoxr --enable-libspeex \
    --enable-libssh --enable-libtesseract --enable-libtheora \
    --enable-libtwolame --enable-libv4l2 --enable-libvo-amrwbenc \
    --enable-libvorbis --enable-libvpx --enable-libwavpack --enable-libwebp \
    --enable-libx264 --enable-libx265 --enable-libxvid --enable-libxml2 \
    --enable-libzmq --enable-libzvbi --enable-lv2 \
    --enable-libmysofa \
    --enable-openal --enable-opencl --enable-opengl --enable-libdrm \
    --enable-libfdk-aac --enable-libbluray \
    && make -j$(nproc) \
    && make install

# Install Nvidia Driver

RUN curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add -

RUN echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

# Install Video2X
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 1 && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 2
RUN  cd / && python3.8 -m pip install --upgrade pip &&\
    git clone --recurse-submodules --progress https://github.com/k4yt3x/video2x.git --depth=1 &&\
    python3.8 -m pip install avalon_framework colorama python-magic patool psutil pyqt5 pyunpack pyyaml requests tqdm

# eg: docker build -t video2x . --build-arg driver=waifu2x_ncnn_vulkan
ARG driver=all

# Check if driver exists.
SHELL ["/bin/bash", "-c"]
RUN drivers=(all waifu2x_caffe waifu2x_converter waifu2x_ncnn_vulkan) &&\
    case ${drivers[@]} in (*${driver,,}*) true ;; (*)\
    echo "ERROR: Unrecognized driver." >&2 &&\
    printf "%s " "Choices are: ${drivers[@]}" >&2 | printf "\n" >&2 &&\
    exit 1 ;;\
    esac

RUN if [ "$driver" = "all" ] || [ "$driver" = "waifu2x_caffe" ] ; then \
    # nagadomi/caffe prerequisites
    apt-fast update &&\
    apt-fast install -y --no-install-recommends build-essential cmake libboost-system-dev libboost-thread-dev libboost-filesystem-dev libboost-chrono-dev libboost-date-time-dev libboost-atomic-dev libboost-python-dev libprotobuf-dev protobuf-compiler libhdf5-dev liblmdb-dev libleveldb-dev libsnappy-dev libopencv-dev libatlas-base-dev python-numpy libgflags-dev libgoogle-glog-dev &&\
    # nagadomi/waifu2x-caffee-ubuntu prerequisites
    apt-fast install -y --no-install-recommends libboost-iostreams-dev;\
    fi
# build waifu2x-caffe && install caffe
RUN if [ "$driver" = "all" ] || [ "$driver" = "waifu2x_caffe" ] ; then \
    git clone --recurse-submodules --depth=1 --progress --recurse-submodules https://github.com/nagadomi/waifu2x-caffe-ubuntu.git &&\
    cd waifu2x-caffe-ubuntu &&\
    git clone --recurse-submodules --progress --depth=1 https://github.com/nagadomi/caffe.git;\
    fi

RUN if [ "$driver" = "all" ] || [ "$driver" = "waifu2x_caffe" ] ; then \
    apt-fast install --no-install-recommends -y gcc-8 libcudnn7 libcudnn7-dev &&\
    apt-get remove -y gcc g++ &&\
    ln -s /usr/bin/gcc-8 /usr/bin/gcc && ln -s /usr/bin/g++-8 /usr/bin/g++ &&\
    cd /waifu2x-caffe-ubuntu &&\
    mkdir build &&\
    cd build &&\
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr &&\
    make -j$(nproc) install;\
    fi

RUN if [ "$driver" = "all" ] || [ "$driver" = "waifu2x_caffe" ] ; then \
    # install waifu2x-caffe
    cd /waifu2x-caffe-ubuntu/build &&\
    cp waifu2x-caffe ../bin/ &&\
    mv ../bin tempname &&\
    mv tempname /video2x/ &&\
    mv /video2x/tempname /video2x/waifu2x-caffe &&\
    rm -rf ../waifu2x-caffe-ubuntu ;\
    fi

RUN if [ "$driver" = "all" ] || [ "$driver" = "waifu2x_ncnn_vulkan" ] ; then \
    apt-fast install -y --no-install-recommends software-properties-common build-essential cmake libvulkan-dev glslang-tools libprotobuf-dev protobuf-compiler &&\
    git clone --recurse-submodules --depth=1 --progress https://github.com/Tencent/ncnn.git &&\
    cd ncnn &&\
    mkdir -p build &&\
    cd build &&\
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DNCNN_VULKAN=ON .. &&\
    make -j$(nproc) install &&\
    rm -rf ../../ncnn &&\
    cd / &&\
    # Compile waifu2x-ncnn-vulkan
    git clone --recurse-submodules --depth=1 --progress https://github.com/nihui/waifu2x-ncnn-vulkan.git &&\
    cd waifu2x-ncnn-vulkan &&\
    mkdir -p build &&\
    cd build &&\
    cmake ../src &&\
    make -j$(nproc) &&\
    # Incall waifu2x-ncnn-vulkan
    cd /waifu2x-ncnn-vulkan &&\
    mkdir waifu2x-ncnn-vulkan &&\
    mv models/models-cunet waifu2x-ncnn-vulkan/ &&\
    mv build/waifu2x-ncnn-vulkan waifu2x-ncnn-vulkan/ &&\
    mv waifu2x-ncnn-vulkan /video2x/ &&\
    rm -rf ../waifu2x-ncnn-vulkan ;\
    fi

RUN if [ "$driver" = "all" ] || [ "$driver" = "waifu2x_converter" ] ;\
    then \
    # Prerequisits for waifu2x-converter-cpp
    apt-fast install -y --no-install-recommends build-essential cmake libopencv-dev ocl-icd-opencl-dev &&\
    # Compile & Install
    git clone --recurse-submodules --depth=1 --progress https://github.com/DeadSix27/waifu2x-converter-cpp &&\
    cd waifu2x-converter-cpp &&\
    mkdir build &&\
    cd build &&\
    cmake .. &&\
    make -j$(nproc) &&\
    #ldconfig &&\
    cp -r ../models_rgb ./&&\
    cd / ;\
    fi

# Go!
#COPY entrypoint.sh /
#ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /host
ENTRYPOINT ["/bin/bash"]

ENV NVIDIA_DRIVER_CAPABILITIES all
# Docker image can ask questions now, if needed.
ENV DEBIAN_FRONTEND teletype

