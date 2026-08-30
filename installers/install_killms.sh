cd $INSTALLDIR
git clone --single-branch -b v3.3.0 https://github.com/saopicc/killMS.git
sed -i '558s/$/ parent_affinity=GDPredict["Parallel"]["MainProcessAffinity"],/' killMS/killMS/kMS.py
sed -i 's/affinity=0/affinity=0, parent_affinity="disable"/' killMS/killMS/SmoothSols.py
sed -i 's/affinity=0/affinity=0, parent_affinity="disable"/' killMS/killMS/InterpSols.py
sed -i 's/affinity=0/affinity=0, parent_affinity="disable"/' killMS/killMS/Weights/W_Imag.py
sed -i 's/affinity=0/affinity=0, parent_affinity="disable"/' killMS/killMS/Weights/W_TimeCov.py
sed -i 's/affinity=0/affinity=0, parent_affinity="disable"/' killMS/killMS/Weights/W_ImagCov.py
uv pip install --no-deps killMS/
