#!/usr/bin/env bash
HELP="$(basename $0)"
if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Extracts tar archives downloaded from the LTA, dysco compresses them and removes the full-resolution flags."
    echo "Usage:"
    echo $HELP
    exit 0
fi
# The average step is a workaround for newer DP3 versions where writefullresflags has been removed.
# Without averaging they remain, but "averaging" with a factor 1 trigger their removal.
set -e
for f in *.tar; do  
    echo $f
    tar xf $f
    msname=$(echo $f | awk -F'_' '{print $1"_"$2"_uv.MS"}')
    echo $msname
    DP3 msin=$msname msout=$(basename $msname .MS).dysco.MS msout.writefullresflag=False msout.storagemanager=dysco steps=[average] average.timestep=1 average.freqstep=1
    rm -rf $msname
    mv $(basename $msname .MS).dysco.MS $msname
    rm $f
done
