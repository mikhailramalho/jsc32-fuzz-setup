FROM debian:bullseye

RUN apt-get -y update
RUN apt-get install -y python3 python3-virtualenv wget git unzip npm zip
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1

COPY setup.sh /tmp/
ARG FUZZDIR=/jscfuzz
ENV JSCFUZZ=${FUZZDIR}
RUN mkdir ${FUZZDIR}
RUN /tmp/setup.sh ${FUZZDIR}

SHELL ["/bin/bash", "-c"]
EXPOSE 8080
CMD source ${JSCFUZZ}/venv/bin/activate && fuzzinator --wui ${JSCFUZZ}/fuzzinator-common.ini ${JSCFUZZ}/jsc-common.ini ${JSCFUZZ}/jsc32-fuzz/configs/fuzzinator.ini ${JSCFUZZ}/jsc32-fuzz/configs/jsc.ini ${JSCFUZZ}/jsc32-fuzz/configs/sut-jsc_local.ini
