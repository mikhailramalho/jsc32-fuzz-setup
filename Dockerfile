ARG ARCH=amd64
FROM docker.io/${ARCH}/debian:buster
ARG ARCH
ARG NCPUS=1
ARG GITLAB_URL
ARG GITLAB_TOKEN
ARG FUZZDIR # set by docker-compose.yml

SHELL ["/bin/bash", "-c"]

# Check arguments
RUN [ -z "$GITLAB_URL" ] && echo "GITLAB_URL is required" && exit 1 || true
RUN [ -z "$GITLAB_TOKEN" ] && echo "GITLAB_TOKEN is required" && exit 1 || true
RUN [ -z "$FUZZDIR" ] && echo "FUZZDIR is required" && exit 1 || true

# Install dependencies
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
    python3-pip \
    python3-virtualenv \
    ruby \
    rustc \
    software-properties-common \
    unzip \
    wget \
    zip
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && apt-get install -y nodejs

WORKDIR ${FUZZDIR}
RUN git clone --depth=1 https://github.com/pmatos/js_fuzzer.git ./js_fuzzer
RUN git clone --depth=1 https://github.com/mikhailramalho/WebKit.git ./webkit
RUN git clone https://github.com/mikhailramalho/fuzzinator.git ./fuzzinator
RUN git clone --depth=1 https://github.com/mikhailramalho/jsc32-fuzz.git ./jsc32-fuzz

ARG WEBKIT=${FUZZDIR}/webkit

RUN if [ "${ARCH}" != "arm32v7" ]; then \
        apt-get install -y gcc-multilib g++-multilib; \
    fi

# /usr/lib for arm32 and /usr/lib64 for x86_64
ENV LD_LIBRARY_PATH=/usr/lib:/usr/lib64
############

# Setup environment
############
ARG WEBTESTS=${FUZZDIR}/web_tests
COPY web_tests.zip ${WEBTESTS}/
WORKDIR ${WEBTESTS}
#RUN wget  https://github.com/pmatos/jsc32-fuzz/releases/download/webtests-20210824/web_tests.zip
RUN unzip -qq web_tests.zip
RUN rm web_tests.zip

ARG JSFUZZER=${FUZZDIR}/js_fuzzer
WORKDIR ${JSFUZZER}
RUN npm install
RUN mkdir db
RUN node build_db.js -i ${WEBTESTS} -o db chakra v8 spidermonkey WebKit/JSTests

ENV JSC32FUZZ=${FUZZDIR}/jsc32-fuzz
ARG FUZZINATOR=${FUZZDIR}/fuzzinator
WORKDIR ${FUZZDIR}
RUN python -m virtualenv --python=python3.7 venv
RUN source venv/bin/activate && \
      pip install ${FUZZINATOR} && \
      pip install picireny && \
      pip install paramiko

ENV PYTHONPATH=${JSC32FUZZ}/fuzzinator:${PYTHONPATH}
COPY setup-files.sh .
RUN ./setup-files.sh

ENV PYTHONPATH=${FUZZDIR}/jsc32-fuzz/fuzzinator

# FUZZDIR is an ARG, we need an alias as an ENV so its seen during runtime
ENV ROOTDIR=${FUZZDIR}
EXPOSE 8080
CMD source ${ROOTDIR}/venv/bin/activate && fuzzinator --wui --bind-ip '0.0.0.0' --port 8080 ${ROOTDIR}/fuzzinator-common.ini ${ROOTDIR}/jsc-common.ini ${ROOTDIR}/jsc32-fuzz/configs/fuzzinator.ini ${ROOTDIR}/jsc32-fuzz/configs/jsc.ini ${ROOTDIR}/jsc32-fuzz/configs/sut-jsc_local.ini
