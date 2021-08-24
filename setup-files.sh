#!/bin/bash

set -e

JSC32FUZZ=$1
WEBKIT=$2
FUZZDIR=$3
ARCH=$4
NCPUS=$5
GITLAB_URL=$6
GITLAB_TOKEN=$7

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
reduce_jobs=${NCPUS}
age=0:12:0:0
timeout=5
arch_prefix=${ARCHPREFIX}

[js-fuzzer.custom]
cwd=${JSFUZZER}
webtests=${WEBTESTS}
EOF
