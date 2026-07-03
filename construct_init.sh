echo export INSTALLDIR=$INSTALLDIR >> $INSTALLDIR/init.sh
echo export FLOCS_VERSION=$FLOCS_VERSION >> $INSTALLDIR/init.sh
echo export EVERYBEAM_DATADIR=\$INSTALLDIR/EveryBeam/share/everybeam >> $INSTALLDIR/init.sh
echo export CASARCFILES=\$INSTALLDIR/.casarc >> $INSTALLDIR/init.sh
echo "measures.directory: $INSTALLDIR/casacore/data" > $INSTALLDIR/.casarc 

echo export LINC_DATA_ROOT=/opt/lofar/LINC >> $INSTALLDIR/init.sh
echo export VLBI_DATA_ROOT=/opt/lofar/VLBI-cwl >> $INSTALLDIR/init.sh

echo export HDF5_DIR=/opt/hdf5 >> $INSTALLDIR/init.sh
echo export HDF5_USE_FILE_LOCKING=$HDF5_USE_FILE_LOCKING >> $INSTALLDIR/init.sh

# Needed for shadems
echo export NUMBA_CACHE_DIR=/tmp >> $INSTALLDIR/init.sh

#
# Check if we are running on supported hardware.
# 
echo export MARCH=$MARCH >> $INSTALLDIR/init.sh
echo export MTUNE=$MTUNE >> $INSTALLDIR/init.sh
echo $'export MARCH_MACHINE=$(gcc -march=native -Q --help=target | grep "\-march=" | head -n 1 | awk \'{print $2}\')' >> $INSTALLDIR/init.sh
echo $'export MTUNE_MACHINE=$(gcc -mtune=native -Q --help=target | grep "\-mtune=" | head -n 1 | awk \'{print $2}\')' >> $INSTALLDIR/init.sh
echo $'if [ "$MARCH_MACHINE" != "$MARCH" ]; then echo "WARNING - software has been build with -march=$MARCH but current machine reports -march=$MARCH_MACHINE.\nIf you encounter strange behaviour or Illegal instruction warnings, consider building a container with the appropriate architecture set."; fi' >> $INSTALLDIR/init.sh
echo $'if [ "$MTUNE_MACHINE" != "$MTUNE" ]; then echo "WARNING - software has been build with -mtune=$MTUNE but current machine -mtune=$MTUNE_MACHINE.\nIf you encounter strange behaviour or Illegal instruction warnings, consider building a container with the appropriate architecture set."; fi' >> $INSTALLDIR/init.sh

# Settings that control threading of BLAS libraries etc.
# OPENBLAS_NUM_THREADS=1 is required for WSClean
echo export NCPU=\$\(nproc\) >> $INSTALLDIR/init.sh
echo export OPENBLAS_NUM_THREADS=1 >> $INSTALLDIR/init.sh
echo export OPENBLAS_MAX_THREADS=\$NCPU >> $INSTALLDIR/init.sh
echo export OMP_NUM_THREADS=\$NCPU >> $INSTALLDIR/init.sh
echo export OMP_MAX_THREADS=\$NCPU >> $INSTALLDIR/init.sh
echo export BLIS_NUM_THREADS=\$OPENBLAS_NUM_THREADS >> $INSTALLDIR/init.sh

#
# Vendor math libraries and CUDA
#
echo export HAS_CUDA=$HAS_CUDA >> $INSTALLDIR/init.sh
if [ "$HAS_CUDA" = true ]; then
    echo export CUDA_HOME=/usr/local/cuda >> $INSTALLDIR/init.sh
    echo export PATH=\$CUDA_HOME/bin:\$PATH >> $INSTALLDIR/init.sh
    echo export LD_LIBRARY_PATH=\$CUDA_HOME/lib64:\$LD_LIBRARY_PATH >> $INSTALLDIR/init.sh
fi

echo export HAS_MKL=$HAS_MKL >> $INSTALLDIR/init.sh
if [ "$HAS_MKL" = false ]; then
    echo flexiblas add OPENBLAS /opt/OpenBLAS/lib64/libopenblas.so >> $INSTALLDIR/init.sh
    echo export FLEXIBLAS=OPENBLAS >> $INSTALLDIR/init.sh

    echo export OPENBLAS_VERSION=$OPENBLAS_VERSION >> $INSTALLDIR/init.sh
    echo export LD_LIBRARY_PATH=/opt/OpenBLAS/lib64:\$LD_LIBRARY_PATH >> $INSTALLDIR/init.sh
else
    # MKLROOT is assumed to exist when this script is sources,
    # which is the case at build time.
    echo export MKLROOT=$MKLROOT >> $INSTALLDIR/init.sh
    echo export PATH=\$MKLROOT/bin:\$PATH >> $INSTALLDIR/init.sh
    echo export LD_LIBRARY_PATH=\$MKLROOT/lib:\$LD_LIBRARY_PATH >> $INSTALLDIR/init.sh
fi

#
# Environment setup for libraries, executables and Python packages.
#
echo export LD_LIBRARY_PATH="/usr/local/lib:\
\$INSTALLDIR/aoflagger/lib:\
\$INSTALLDIR/casacore/lib:\
\$INSTALLDIR/DP3/lib:\
\$INSTALLDIR/EveryBeam/lib:\
\$INSTALLDIR/idg/lib:\
\$INSTALLDIR/lofar/lib:\
\$INSTALLDIR/lofar/lib64:\
\$INSTALLDIR/sagecal/lib:\
\$INSTALLDIR/lofarstman/lib64:\
\$INSTALLDIR/MultiNest/lib:\
/opt/hdf5/lib:\
/usr/lib64/openmpi/lib/:\
\$LD_LIBRARY_PATH" >> $INSTALLDIR/init.sh

echo export PATH="/root/.local/bin/:\
/opt/hdf5/bin:\
/usr/lib64/openmpi/bin:\
\$INSTALLDIR/aoflagger/bin:\
\$INSTALLDIR/casacore/bin:\
\$INSTALLDIR/ds9/bin:\
\$INSTALLDIR/DP3/bin:\
\$INSTALLDIR/wsclean/bin:\
\$INSTALLDIR/runners:\
\$INSTALLDIR/VLBI-cwl/scripts:\
\$INSTALLDIR/utility:\
\$INSTALLDIR/MultiNest/bin:\
\$INSTALLDIR/stilts:\
\$INSTALLDIR/LINC/scripts:\$PATH" >> $INSTALLDIR/init.sh

echo export PYTHONPATH="\$INSTALLDIR/VLBI-cwl/scripts:\
\$INSTALLDIR/LINC/scripts:\
\$INSTALLDIR/aoflagger/lib:\
\$INSTALLDIR/lofar/lib64/python$PYTHON_VERSION/site-packages:\
\$INSTALLDIR/DP3/lib/python$PYTHON_VERSION/site-packages:\
\$INSTALLDIR/DP3/usermodules:\
\$INSTALLDIR/EveryBeam/lib64/python$PYTHON_VERSION/site-packages:\
\$INSTALLDIR/lotss-hba-survey:\
\$INSTALLDIR/lotss-query:\
\$INSTALLDIR/ddf-pipeline/scripts:\
\$INSTALLDIR/ddf-pipeline/utils:\
\$INSTALLDIR/DDFacet/DDFacet:\
\$INSTALLDIR/DynSpecMS:\
\$PYTHONPATH" >> $INSTALLDIR/init.sh

#
# DDF-specific settings
#
echo "# DDF environment settings" >> $INSTALLDIR/init.sh
echo export DDF_DIR=$INSTALLDIR >> $INSTALLDIR/init.sh
echo export DDF_PIPELINE_CATALOGS=$INSTALLDIR/DDFCatalogues >> $INSTALLDIR/init.sh
echo export KILLMS_DIR=$INSTALLDIR >> $INSTALLDIR/init.sh
echo export PATH="\$INSTALLDIR/DynSpecMS/:\
\$INSTALLDIR/ddf-pipeline/scripts:\
\$PATH" >> $INSTALLDIR/init.sh
echo "if echo \$(hostname) | grep -qi leiden; then export DDF_PIPELINE_CLUSTER="paracluster"; else export DDF_PIPELINE_CLUSTER=; fi" >> $INSTALLDIR/init.sh

