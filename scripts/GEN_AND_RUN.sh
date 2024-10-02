#!/bin/sh

WORKINGDIR=${WORKINGDIR:-ICS-$$}


mv Cloud-Sandbox/ working.Cloud-Sandbox
git clone https://github.com/ioos/Cloud-Sandbox.git hsofs.Cloud-Sandbox
cd hsofs.Cloud-Sandbox/
git checkout hsofs-fix

cd models/adcirc-cora/
vi cleanme.sh
./cleanme.sh

vi buildadcirc.sh
./buildadcirc.sh

./buildadcirc.sh > & build.out &
tail -f build.out
cp -p configs/* /save/<yourfolder>/cora-runs/ADCIRC/configs
cp -p common/* /save/<yourfolder>/cora-runs/ADCIRC/common

cds
cd hsofs.Cloud-Sandbox
cd cluster/configs/
cd ../..
cd job/jobs
cds
cd cora-runs
mv ADCIRC ..
mv Forcing ..
cd ADCIRC
ln -s ../Forcing .
cd ERAf/hsofs
rm -Rf 2018/
cds
cd hsofs.Cloud-Sandbox/cloudflow
./workflows/workflow_main.py job/jobs/test.hsofs.short > & short.out &

 

