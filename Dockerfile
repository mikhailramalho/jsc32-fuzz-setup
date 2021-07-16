ARG ARCH=amd64
FROM docker.io/${ARCH}/debian:buster
ARG ARCH
ARG NCPUS=1
ARG GITLAB_URL
ARG GITLAB_TOKEN

RUN apt-get update && apt-get install -y \
    cmake \
    curl \
    default-jdk \
    g++ \
    gcc \
    gdb \
    git \
    libffi-dev \
    libicu-dev \
    libssl-dev \
    python3 \
    python3-dev \
    python3-virtualenv \
    ruby \
    rustc \
    software-properties-common \
    unzip \
    wget \
    zip
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && apt-get install -y nodejs

ARG FUZZDIR=/jscfuzz
COPY WebKit.git/ /webkit.git
WORKDIR ${FUZZDIR}
RUN git clone -q --depth=1 file:////webkit.git ./webkit

WORKDIR ${FUZZDIR}/webkit
RUN git remote set-url origin https://github.com/WebKit/WebKit.git
RUN git fetch origin
RUN git checkout -b main origin/main || true
RUN git reset --hard origin/main

WORKDIR ${FUZZDIR}
RUN git clone -q --depth=1 https://github.com/pmatos/js_fuzzer.git ./js_fuzzer
RUN git clone -q --depth=1 https://github.com/pmatos/jsc32-fuzz.git ./jsc32-fuzz
RUN git clone -q --depth=1 https://github.com/renatahodovan/fuzzinator.git ./fuzzinator

# Build GCC 9
#############
RUN apt-get install -y \
    build-essential \
    libc6-dev \
    libgmp-dev \
    libmpc-dev \
    libmpfr-dev \
    texinfo \
    wget
RUN if [ "${ARCH}" != "arm32v7" ]; then \
        apt-get install -y gcc-multilib g++-multilib; \
    fi
RUN rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN wget https://mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-9.4.0/gcc-9.4.0.tar.gz
RUN tar -xvzf gcc-9.4.0.tar.gz

WORKDIR /tmp/gcc-build
RUN if [ "${ARCH}" = "arm32v7" ]; then \
        ../gcc-9.4.0/configure --prefix=/usr \
                               --enable-languages=c,c++,lto \
                               --program-suffix=-9 \
                               --with-arch=armv7-a \
                               --with-fpu=vfpv3-d16 \
                               --with-float=hard \
                               --with-mode=thumb \
                               --disable-werror \
                               --enable-checking=yes \
                               --enable-shared \
                               --enable-linker-build-id \
                               --libexecdir=/usr/lib \
                               --without-included-gettext \
                               --enable-threads=posix \
                               --libdir=/usr/lib \
                               --enable-nls \
                               --enable-bootstrap \
                               --enable-clocale=gnu \
                               --enable-libstdcxx-debug \
                               --enable-libstdcxx-time=yes \
                               --with-default-libstdcxx-abi=new \
                               --enable-gnu-unique-object \
                               --disable-libitm \
                               --disable-libquadmath \
                               --disable-libquadmath-support \
                               --enable-plugin \
                               --enable-default-pie \
                               --enable-objc-gc=auto \
                               --enable-multiarch \
                               --disable-sjlj-exceptions \
                               --build=arm-linux-gnueabihf \
                               --host=arm-linux-gnueabihf \
                               --target=arm-linux-gnueabihf; \
    else \
        ../gcc-9.4.0/configure --prefix=/usr \
                               --enable-languages=c,c++,lto \
                               --disable-werror \
                               --enable-checking=yes \
                               --program-suffix=-9 \
                               --enable-bootstrap \
                               --disable-multilib \
                               --disable-docs \
                               --disable-nls; \
    fi
RUN make -j${NCPUS} && make -j${NCPUS} install

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 50
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 50

############
WORKDIR /tmp
COPY setup.sh .
ENV JSCFUZZ=${FUZZDIR}

# /usr/lib for arm32 and /usr/lib64 for x86_64
ENV LD_LIBRARY_PATH=/usr/lib:/usr/lib64

RUN /tmp/setup.sh ${FUZZDIR} ${NCPUS} ${ARCH} ${GITLAB_URL} ${GITLAB_TOKEN}

ENV PYTHONPATH=${FUZZDIR}/jsc32-fuzz/fuzzinator
EXPOSE 8080
SHELL ["/bin/bash", "-c"]
CMD source ${JSCFUZZ}/venv/bin/activate && fuzzinator --wui --bind-ip '0.0.0.0' --port 8080 ${JSCFUZZ}/fuzzinator-common.ini ${JSCFUZZ}/jsc-common.ini ${JSCFUZZ}/jsc32-fuzz/configs/fuzzinator.ini ${JSCFUZZ}/jsc32-fuzz/configs/jsc.ini ${JSCFUZZ}/jsc32-fuzz/configs/sut-jsc_local.ini
