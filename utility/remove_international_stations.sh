#!/usr/bin/env bash
HELP="$(basename $0) <msin> <msout>"
if [[ $1 == "-h" || $1 == "--help" || $# == 0 ]]; then
    echo "Remove international stations from a Measurement Set using DP3."
    echo
    echo "Usage:"
    echo $HELP
    exit 0
fi
DP3 msin=$1 msout=$2 steps=[filter] filter.remove=True filter.baseline='[CR]S*&'
