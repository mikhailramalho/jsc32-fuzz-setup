ARG ARCH=amd64
FROM docker.io/${ARCH}/debian:buster
ARG FUZZDIR
ARG NCPUS=1

RUN apt-get -y update
RUN apt-get install -y python3 python3-dev python3-virtualenv libffi-dev wget git unzip zip curl software-properties-common cmake g++ gcc ruby libicu-dev rustc libssl-dev
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs
RUN node -v
RUN npm -v
RUN python --version

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

COPY setup.sh /tmp/
ENV JSCFUZZ=${FUZZDIR}
RUN /tmp/setup.sh ${FUZZDIR} ${NCPUS} ${ARCH}

EXPOSE 8080
SHELL ["/bin/bash", "-c"]
CMD source ${JSCFUZZ}/venv/bin/activate && fuzzinator --wui --bind-ip '0.0.0.0' --port 8080 ${JSCFUZZ}/fuzzinator-common.ini ${JSCFUZZ}/jsc-common.ini ${JSCFUZZ}/jsc32-fuzz/configs/fuzzinator.ini ${JSCFUZZ}/jsc32-fuzz/configs/jsc.ini ${JSCFUZZ}/jsc32-fuzz/configs/sut-jsc_local.ini
