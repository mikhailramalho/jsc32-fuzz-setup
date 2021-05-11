#!/bin/bash -x

set -e

DESTDIR=$1
NCPUS=$2
ARCH=$3
GITLAB_URL=$4
GITLAB_TOKEN=$5

echo "Arguments:"
echo "DESTDIR: ${DESTDIR}"
echo "NCPUS: ${NCPUS}"
echo "ARCH: ${ARCH}"
echo "GITLAB_URL: ${GITLAB_URL}"
echo "GITLAB_TOKEN: ${GITLAB_TOKEN}"

# Component dirs
JSFUZZER=${DESTDIR}/js_fuzzer
JSC32FUZZ=${DESTDIR}/jsc32-fuzz
FUZZINATOR=${DESTDIR}/fuzzinator
WEBKIT=${DESTDIR}/webkit

# Assets
WEBTESTS=${DESTDIR}/web_tests

# All the software is now set in the correct place.
echo "Software now in the correct folders:"
echo "js_fuzzer        : ${JSFUZZER}"
echo "jsc32-fuzz       : ${JSC32FUZZ}"
echo "fuzzinator       : ${FUZZINATOR}"
echo "WebKit           : ${WEBKIT}"
echo

cd ${DESTDIR}

echo "Downloading Web Tests assets"
mkdir ${WEBTESTS}
wget -P ${WEBTESTS} https://github.com/pmatos/jsc32-fuzz/releases/download/webtests-20210211/web_tests.zip
cd ${WEBTESTS}
unzip -qq web_tests.zip
rm web_tests.zip

# Setup JS Fuzzer
cd ${JSFUZZER}
npm install
mkdir db
node build_db.js -i ${WEBTESTS} -o db chakra v8 spidermonkey WebKit/JSTests

# Setup python environment
echo "Setting up python environment"
cd ${DESTDIR}
python -m virtualenv --python=python3.7 venv
source venv/bin/activate

pip install ${FUZZINATOR}
export PYTHONPATH=${JSC32FUZZ}/fuzzinator:${PYTHONPATH}

# If we are building for arm32 we need the linux32 prefix
if [ "${ARCH}" == "arm32v7" ]; then
    ARCHPREFIX="linux32"
else
    ARCHPREFIX=
fi

# Setup fuzzinator common config file
cd ${DESTDIR}
cat <<EOF > ./fuzzinator-common.ini
[fuzzinator.custom]
config_root=${JSC32FUZZ}
db_uri=mongodb://db/fuzzinator
db_server_selection_timeout=30000
cost_budget=${NCPUS}
work_dir=${DESTDIR}/fuzzinator-tmp
gitlab_url=${GITLAB_URL}
gitlab_project=jsc-fuzzing
gitlab_token=${GITLAB_TOKEN}
EOF

cat <<EOF > ./jsc-common.ini
[jsc]
root_dir=${WEBKIT}
reduce_jobs=1
age=1:0:0:0
timeout=1
arch_prefix=${ARCHPREFIX}

[js-fuzzer.custom]
cwd=${JSFUZZER}
webtests=${WEBTESTS}
EOF
