#!/bin/bash

set -e

JSC32FUZZ=$1
WEBKIT=$2
JSFUZZER=$3
WEBTESTS=$4
FUZZDIR=$5
ARCH=$6
NCPUS=$7
GITLAB_URL=$8
GITLAB_TOKEN=$9

# If we are building for arm32 we need the linux32 prefix
if [ "${ARCH}" == "arm32v7" ]; then
    ARCHPREFIX="linux32"
else
    ARCHPREFIX=
fi

echo "Finalizing setup:"
echo "  * ARCH: ${ARCH}"
echo "  * ARCHPREFIX: ${ARCHPREFIX}"
echo "  * FUZZDIR: ${FUZZDIR}"
echo "  * JSC32FUZZ: ${JSC32FUZZ}"
echo "  * WEBTESTS: ${WEBTESTS}"
echo "  * WEBKIT: ${WEBKIT}"
echo "  * JSFUZZER: ${JSFUZZER}"
echo "  * NCPUS: ${NCPUS}"
echo "  * GITLAB_URL: ${GITLAB_URL}"
echo "  * GITLAB_TOKEN: ${GITLAB_TOKEN}"
echo

# Setup fuzzinator common config file
cat <<EOF > ${FUZZDIR}/fuzzinator-common.ini
[fuzzinator.custom]
config_root=${JSC32FUZZ}
db_uri=mongodb://db/fuzzinator
db_server_selection_timeout=30000
cost_budget=${NCPUS}
work_dir=${FUZZDIR}/fuzzinator-tmp
gitlab_url=${GITLAB_URL}
gitlab_project=jsc-fuzzing
gitlab_token=${GITLAB_TOKEN}
EOF

cat <<EOF > ${FUZZDIR}/jsc-common.ini
[jsc]
root_dir=${WEBKIT}
reduce_jobs=${NCPUS}
age=0:12:0:0
timeout=5
arch_prefix=${ARCHPREFIX}

[js-fuzzer.custom]
cwd=${JSFUZZER}
webtests=${WEBTESTS}
EOF
