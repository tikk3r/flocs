#!/usr/bin/env bash
# See https://www.astron.nl/lofarwiki/doku.php?id=public:lta_howto
HELP="$(basename $0)"
if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Renames tar archives downloaded from the LTA that starts with SRMifoGet* to their proper name."
    echo "Usage:"
    echo $HELP
    exit 0
fi
find . -name "SRMFifoGet*" | awk -F %2F '{system("mv "$0" "$NF)}'