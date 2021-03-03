FROM debian:buster

RUN apt-get -y update
RUN apt-get install -y python3 python3-virtualenv wget git unzip zip curl software-properties-common cmake g++ gcc ruby libicu-dev
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get update
RUN apt-get install -y nodejs
RUN node -v
RUN npm -v
RUN python --version

COPY setup.sh /tmp/
ARG FUZZDIR=/jscfuzz
ENV JSCFUZZ=${FUZZDIR}
RUN mkdir ${FUZZDIR}
RUN /tmp/setup.sh ${FUZZDIR}

EXPOSE 8080
SHELL ["/bin/bash", "-c"]
CMD source ${JSCFUZZ}/venv/bin/activate && fuzzinator --wui --bind-ip '0.0.0.0' --port 8080 ${JSCFUZZ}/fuzzinator-common.ini ${JSCFUZZ}/jsc-common.ini ${JSCFUZZ}/jsc32-fuzz/configs/fuzzinator.ini ${JSCFUZZ}/jsc32-fuzz/configs/jsc.ini ${JSCFUZZ}/jsc32-fuzz/configs/sut-jsc_local.ini
