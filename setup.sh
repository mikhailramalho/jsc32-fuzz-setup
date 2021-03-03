#! /bin/bash

set -e

DESTDIR=$1
mkdir -p ${DESTDIR}

# Component dirs
JSFUZZER=${DESTDIR}/js_fuzzer
JSC32FUZZ=${DESTDIR}/jsc32-fuzz
FUZZINATOR=${DESTDIR}/fuzzinator
WEBKIT=${DESTDIR}/webkit

# Assets
WEBTESTS=${DESTDIR}/web_tests

echo "Cloning components"
echo

# Copy js_fuzzer to destdir
git clone https://github.com/pmatos/js_fuzzer.git ${JSFUZZER}

# Copy jsc32-fuzz to destdir
git clone https://github.com/pmatos/jsc32-fuzz.git ${JSC32FUZZ}

# Copy fuzzinator to destdir
git clone https://github.com/renatahodovan/fuzzinator.git ${FUZZINATOR}

# Clone webkit to destdir
git clone https://github.com/WebKit/WebKit.git ${WEBKIT}

# All the software is now set in the correct place.
echo "Software now in the correct folders:"
echo "js_fuzzer        : ${JSFUZZER}"
echo "jsc32-fuzz       : ${JSC32FUZZ}"
echo "fuzzinator       : ${FUZZINATOR}"
echo "WebKit           : ${WEBKIT}"
echo

echo "Downloading Web Tests assets"
mkdir ${WEBTESTS}
wget -P ${WEBTESTS} https://github.com/pmatos/jsc32-fuzz/releases/download/webtests-20210211/web_tests.zip
cd ${WEBTESTS}
unzip web_tests.zip
rm web_tests.zip

# Setup JS Fuzzer
cd ${JSFUZZER}
npm install
mkdir db
node build_db.js -i ${WEBTESTS} -o db chakra v8 spidermonkey WebKit/JSTests
./node_modules/.bin/pkg -t node10-linux-x64 .
./package.sh

# Setup python environment
echo "Setting up python environment"
cd ${DESTDIR}
python -m virtualenv --python=python3.7 venv
source venv/bin/activate

pip install ${FUZZINATOR}
export PYTHONPATH=${JSC32FUZZ}/fuzzinator:${PYTHONPATH}

# Setup fuzzinator common config file
cd ${DESTDIR}
cat <<EOF > ./fuzzinator-common.ini
[fuzzinator.custom]
config_root=${JSC32FUZZ}
db_uri=mongodb://db/fuzzinator
db_server_selection_timeout=30000
cost_budget=$(nproc)
work_dir=${DESTDIR}/fuzzinator-tmp
EOF

cat <<EOF > ./jsc-common.ini
[jsc]
root_dir=${WEBKIT}
reduce_jobs=1
age=1:0:0:0
timeout=1
# Optional, only needed to send authenticated requests
# to Bugzilla (find/report issues).
api_key=

[js-fuzzer.custom]
cwd=${JSFUZZER}
webtests=${WEBTESTS}
EOF
