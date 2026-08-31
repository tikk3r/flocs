cd $INSTALLDIR
wget --progress=bar:force:noscroll https://lta.lofar.eu/software/lofar_lta-2.8.0.tar.gz
tar xf lofar_lta-*
cd lofar_lta-2.8.0
uv pip install .
cd ..
rm lofar_lta*.tar.gz
rm -rf lofar_lta-2.8.0/
