cd $INSTALLDIR
git clone --single-branch -b v0.9.1 https://github.com/saopicc/DDFacet.git
sed -i '30d' DDFacet/DDFacet/Imager/ClassFrequencyMachine.py
sed -i 's/:#//' DDFacet/DDFacet/Data/ClassVisServer.py
uv pip install --no-deps DDFacet/
