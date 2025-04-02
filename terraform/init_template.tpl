#!/usr/bin/env bash
set -x

echo `date` > ~/setup.log

# RHEL8+
RUNUSER="ec2-user"

# CentOS 7 - Stream 8
#RUNUSER="centos"

export BRANCH=feature/trial
#BRANCH=origin/x86_64
#BRANCH=origin/formainpr

export EFS_VERS='v1.36.0'

# Mount the EFS volume

mkdir -p /mnt/efs/fs1
sudo yum -y -q install git 

sudo yum -y install amazon-efs-utils

if [ $? -ne 0 ]; then
  echo "amazon-efs-utils not found, trying to build from source..."
  # Error: Unable to find a match: amazon-efs-utils
  # Alternate method
  sudo yum -y install rpm-build make
#  sudo yum -y install openssl-devel
#  sudo yum -y install cargo
#  sudo yum -y install rust
  cd /tmp
  git clone -b $EFS_VERS https://github.com/aws/efs-utils
  cd efs-utils
  sudo make rpm
  sudo yum -y install ./build/amazon-efs-utils*rpm
  cd /tmp
fi

echo "Waiting for EFS to be available..."
RETVAL=-1
COUNT=0
while [ $RETVAL -ne 0 ]; do
  if [ $COUNT -gt 0 ]; then
    sleep 5
    echo "Retrying to mount EFS..."
    COUNT=$(expr $COUNT + 1)
    if [ $COUNT -gt 10 ]; then
      echo "EFS mount failed after 10 attempts. Exiting."
      exit 1
    fi
  fi
  echo "Trying to mount EFS..."
  mount -t efs "${efs_name}" /mnt/efs/fs1
  RETVAL=$?
done
echo "${efs_name} /mnt/efs/fs1 efs defaults 0 0" >> /etc/fstab

cd /mnt/efs/fs1
if [ ! -d save ] ; then
  sudo mkdir save
  sudo chgrp wheel save
  sudo chmod 777 save
  sudo ln -s /mnt/efs/fs1/save /save
fi

cd /mnt/efs/fs1/save
sudo mkdir $RUNUSER
sudo chown $RUNUSER:$RUNUSER $RUNUSER
cd $RUNUSER
sudo -u $RUNUSER git clone https://github.com/LynkerIntel/IOOS-Cloud-Sandbox.git
cd IOOS-Cloud-Sandbox
sudo -u $RUNUSER git checkout --track origin/$BRANCH
cd scripts

# Need to pass ami_name
export ami_name=${ami_name}
echo "ami name : $ami_name"

# Install all of the software and drivers
sleep 10
sudo -E -u $RUNUSER ./setup-instance.sh >> ~/setup.log 2>&1

# TODO: Check for errors returned from any step above

echo "Installation completed!" >> ~/setup.log
echo `date` >> ~/setup.log
