#!/usr/bin/env bash
set -e

cd /save/$USERNAME || exit 1

files="2018.ioos_sb.tgz
       adcirc_built.tgz
       cora-runs.tgz"

for f in $files
do
  aws s3 cp s3://lcsb-cloud-sandbox-working/public/cora-adcirc/$f .
  tar -xvf $f
done
