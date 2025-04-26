#!/usr/bin/env bash
if [[ -z $LINC_DATA_ROOT ]]; then
    echo "LINC_DATA_ROOT has to be set."
fi

cd $LINC_DATA_ROOT
LINC_VERSION = $(git describe --tags)

VERSIONS_FILE=${LINC_DATA_ROOT}/.versions
"LINC: "${LINC_VERSION}"\n"  > ${VERSIONS_FILE}
pip freeze | sed 's/==/: /g' >> ${VERSIONS_FILE}
