cd $INSTALLDIR
git clone https://github.com/mhardcastle/ddf-pipeline.git
cd ddf-pipeline
git checkout $DDFPIPELINE_VERSION
cd ..
sed -i "s/DDF.py/DDF.py --Misc-IgnoreDeprecationMarking=1/" $INSTALLDIR/ddf-pipeline/scripts/pipeline.py
sed -i "s/--Beam-PhasedArrayMode/--Beam-LOFARBeamMode/g" $INSTALLDIR/ddf-pipeline/scripts/pipeline.py
sed -i "s/--PhasedArrayMode/--LOFARBeamMode/g" $INSTALLDIR/ddf-pipeline/scripts/pipeline.py
sed -i "s/pybdsm\.srl\.fits/pybdsf\.srl\.fits/g" $INSTALLDIR/ddf-pipeline/scripts/pipeline.py
sed -i "s/pybdsm\.srl\.fits/pybdsf\.srl\.fits/g" $INSTALLDIR/ddf-pipeline/scripts/bootstrap.py
sed -i '353s/readonly=True/readonly=False/' $INSTALLDIR/ddf-pipeline/utils/auxcodes.py
mkdir $INSTALLDIR/DDFCatalogues
cd $INSTALLDIR/DDFCatalogues
wget --progress=bar:force:noscroll https://www.extragalactic.info/bootstrap/VLSS.fits
wget --progress=bar:force:noscroll https://www.extragalactic.info/bootstrap/wenss.fits
wget --progress=bar:force:noscroll https://www.extragalactic.info/bootstrap/B2.fits
wget --progress=bar:force:noscroll https://www.extragalactic.info/bootstrap/NVSS.fits
#wget --progress=bar:force:noscroll https://lambda.gsfc.nasa.gov/data/foregrounds/tgss_adr/TGSSADR1_7sigma_catalog.fits
wget --progress=bar:force:noscroll http://tgssadr.strw.leidenuniv.nl/catalogs/TGSSADR1_7sigma_catalog.fits
cd $INSTALLDIR

sed -i 's/SafeConfigParser/ConfigParser/g' /opt/lofar/ddf-pipeline/utils/options.py
