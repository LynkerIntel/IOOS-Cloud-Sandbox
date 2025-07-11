import logging
import subprocess
import time
import traceback
import json
import os
import re
import inspect

import boto3
from botocore.exceptions import ClientError
from prefect.engine import signals

from cloudflow.job.Job import Job
from cloudflow.cluster.Cluster import Cluster

from cloudflow.services.ScratchDisk import ScratchDisk, readConfig

import cloudflow.services.ScratchDisk as ScratchDiskModule

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

log = logging.getLogger('workflow')

class FSxScratchDisk(ScratchDisk):
    """ AWS FSx for Lustre implementation of scratch disk.
        Can only have one at a time. Assumes all jobs will use the same scratch disk and path
    """

    ### PT 2/13/2025 - HERE - why can we only have one at a time?

    ''' Note: df  /ptmp provides the following details:
        df /ptmp | grep -v 'Filesystem' | grep tcp | awk '{print $1}'
        10.0.0.5@tcp:/2y2xnbmv
    '''

    ''' TODO: Reuse the existing scratch disk if one exists 
        This will be needed if running multiple forecasts at once, otherwise make the ptmp parameter different
        Possible solution:

            Create a unique identifier for this instance : use a class attribute to store this
            Also place a file at /ptmp of this unique id e.g. user.{self.id}
            When done, remove the user.{self.id} file 
            If there are no other user.files then the scratch disk can be unmounted and deleted
    '''

    def __init__(self, cluster: Cluster, job: Job):
        """ Constructor """

        self.mountname: str = None
        self.dnsname: str = None
        self.filesystemid: str = None
        self.status: str = 'uninitialized'

        self.provider: str = 'AWS'
        self.capacity: int = 1200   # The smallest is 1.2 TB

        self.tags = cluster.tags
        self.sg_ids = cluster.sg_ids
        self.subnet_id = cluster.subnet_id
        self.region = cluster.region
        self.mountpath = job.PTMP

        self.username = os.environ.get('USER')

        return


    def _mountexists(self) -> bool:
        """ Check to see if a disk is already mounted at mountpath """
        # df /ptmp (EFS): fs-46891ac5.efs.us-east-1.amazonaws.com:/   /mnt/efs/fs1
        # df /ptmp (FSx): 10.0.0.5@tcp:/2y2xnbmv 
        if os.path.isdir(self.mountpath):
            result = subprocess.run(['df', '--output=source', self.mountpath], encoding='utf-8', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            source = result.stdout.split()[1]
            if re.search(".efs.", source) or re.search("@tcp:/", source):
                return True
            else: return False 
        else:
            return False   
 

    def create(self):
        """ Create a new FSx scratch disk and mount it locally 

        Parameters
        ----------
        mountpath : str
            The path where the disk will be mounted. Default = /ptmp" (optional)
        """

        log.debug(f"In: {self.__class__.__name__} : {inspect.currentframe().f_code.co_name}")

        # Check to see if an FSx scratch disk already exists on the system at mountpath
        # Add an additional lock to it, since multiple runs might be using the same FSx disk

        # Place a lock file for this workflow
        self.lockid = ScratchDiskModule.addlock(self.mountpath)

        os.makedirs(self.mountpath, exist_ok=True)

        client = boto3.client('fsx', region_name=self.region)

        if self._mountexists(): 

            log.info(f"A disk is already mounted at {self.mountpath}")

            # Need to obtain the details, so we can delete it here if we are last to use it
            # Assume it is an FSx disk and not an EFS disk. 
            #               Mountname
            # 10.0.1.70@tcp:/gcuupbmv
            # Need FileSystemId': 'string',
            # we can get mountname from df
        
            #result = subprocess.run(['df', '--output=source', '/ptmp'], encoding='utf-8', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            result = subprocess.run(['df', '--output=source', self.mountpath], encoding='utf-8', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            dfmountname = result.stdout.split()[1].split('/')[1]
            log.debug(f"dfmountname: {dfmountname}")

            # search existing FileSystems list for mountname
            filesystems = client.describe_file_systems()['FileSystems']
            index = 0
            for fs in filesystems:
                mountname = fs['LustreConfiguration']['MountName']
                if mountname == dfmountname:
                    self.filesystemid = fs['FileSystemId']
                    self.dnsname = fs['DNSName']
                    self.mountname = mountname
                    # TODO: might not be the correct logic here
                    log.info(f'Found an existing FSx disk {fs["DNSName"]} {mountname} at {self.mountpath}. We will use that.')
                    break
                else:
                    index += 1
                    if index == len(filesystems):  # raise signal after exhausting list
                        log.exception(f'ERROR: a filesystem mount exists: {dfmountname} at {self.mountpath}, \
                                        but unable to locate a matching FSx disk') 
                        raise signals.FAIL()
                    continue
            return  # scratch disk already exists, don't create a new one

        elif ScratchDiskModule.get_lockcount(self.mountpath) == 1: 
            # Mount does not exist, but another process might be creating it 
            # We just created a lock for this, so lock count must be == 1 if we are the only one starting it
            # The locks exist in case a batch of runs are started that are cofigured to use the same scratch mount path

            log.debug(f"Using boto3 to create FSx scratch: in get_lockount == 1")
            
            try:
                response = client.create_file_system(
                    FileSystemType='LUSTRE',
                    StorageCapacity=self.capacity,
                    SubnetIds=[ self.subnet_id ],
                    SecurityGroupIds=self.sg_ids,
                    Tags=self.tags,
                    LustreConfiguration={
                        'DeploymentType': 'SCRATCH_2'
                    }
                )

                self.status='creating'
                self.filesystemid = response['FileSystem']['FileSystemId']
                self.dnsname = response['FileSystem']['DNSName']
                self.mountname = response['FileSystem']['LustreConfiguration']['MountName']
                log.debug(f"filesystemid: {self.filesystemid}, dnsname: {self.dnsname}, mountname: {self.mountname}")

            except ClientError as e:
                log.exception('ClientError exception in create FSx mount' + str(e))
                raise signals.FAIL()
        
                '''
                  'FileSystems': {
                      FileSystemId': 'string',
                      'DNSName': 'string',
                      'LustreConfiguration': {
                           'MountName': 'string'
            
                '''

            log.info("FSx drive creation in progress...")

            # TODO: wait for scratch to become available here instead of in __mount
            log.debug(f"Attempting to mount scratch ...")
            # Now mount it
            self.__mount()
        return


    def __mount(self):
        """ Mount the disk when it is ready """

        log.debug(f"In: {self.__class__.__name__} : {inspect.currentframe().f_code.co_name}")

        # sudo mount -t lustre -o 'noatime,flock' fs-037d74a7524d3e1d3.fsx.us-east-1.amazonaws.com@tcp:/gcuupbmv /ptmp

        client = boto3.client('fsx', region_name=self.region)

        maxtries=15
        delay=60

        os.makedirs(self.mountpath, exist_ok=True)

        # Wait for it to be ready
        log.info("Waiting for FSx disk to become AVAILABLE ... ")
        log.info("... this usually takes about 6 minutes but could take up to 12 minutes")

        for x in range(maxtries):

            if x == maxtries-1:
                log.exception('maxtries exceeded waiting for disk to become available ...')
                raise signals.FAIL()

            response = client.describe_file_systems(FileSystemIds=[self.filesystemid])
            # print(response)
            # 'Lifecycle': 'AVAILABLE' | 'CREATING' | 'FAILED' | 'DELETING' | 'MISCONFIGURED' | 'UPDATING',
            status = response['FileSystems'][0]['Lifecycle']

            # Mount it
            if status == 'AVAILABLE':
                log.info("FSx scratch disk is ready.")

                try:
                    ''' sudo mount -t lustre -o noatime,flock fs-0efe931e2cc043a6d.fsx.us-east-1.amazonaws.com@tcp:/6i6xxbmv  /ptmp '''
                    log.info("Attempting to mount it locally...")


                    log.debug(f"sudo mount -t lustre -o noatime,flock {self.dnsname}@tcp:/{self.mountname} self.mountpath  ")
                    # Note: Need to allow sudo mount for all users
                    result = subprocess.run(['sudo', 'mount', '-t', 'lustre', '-o', 'noatime,flock', 
                                            f'{self.dnsname}@tcp:/{self.mountname}', self.mountpath ],
                                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

                    if result.returncode != 0:
                        log.debug(result.stdout)
                        log.exception('error attempting to mount scratch disk ...')
                        raise signals.FAIL()
                    else:
                        # Note: sudoers privs need to be setup for users
                        result = subprocess.run(['sudo', 'chown', f'{self.username}:{self.username}', self.mountpath ],
                                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

                except Exception as e:
                    log.exception('unable to mount scratch disk ...')
                    traceback.print_stack()
                    raise signals.FAIL()

                self.status='available'
                log.info(f"FSx scratch is mounted locally at {self.mountpath}")
                break
            else: 
                log.info(f"Waiting for FSx disk to become AVAILABLE ... {x}")
                time.sleep(delay)
        return


    def delete(self):
        """ Delete this FSx disk """

        log.debug(f'Attempting to delete FSx disk at {self.mountpath}')
        log.debug(f'This processes lockid: {self.lockid}')

        # Remove the lock for this incantation
        ScratchDiskModule.removelock(self.mountpath, self.lockid)

        # Is the disk in use by anyone else? There is a potential for a race condition here.
        # If another process is blocking on entering the mutex to add a lock, this process will still remove the disk
        # TODO: possibly make __acquire non-blocking
        if ScratchDiskModule.haslocks(self.mountpath):
            log.info(f'FSx disk at {self.mountpath} is currently in use by another job. Unable to remove it.')
            return
     
        log.info(f'Unmounting FSx disk at {self.mountpath} ...')
        try:
            # umount -f = force, -l = lazy
            # -f requires sudo
            #result = subprocess.run(['umount', '-fl', self.mountpath ],
            result = subprocess.run(['sudo', 'umount', '-fl', self.mountpath ],
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            if result.returncode != 0:
                print(result.stdout)
                log.error(f'Non-zero return code {result.returncode} while unmounting scratch disk at {self.mountpath} ...')
            else:
                os.rmdir(self.mountpath)

        except OSError as e:
            log.exception(f'OSError {e} : {self.mountpath}')

        except Exception as e:
            log.exception('Exception while unmounting scratch disk at {self.mountpath} ...')

        # Remove the AWS FSx resource
        client = boto3.client('fsx', region_name=self.region)
        try:
            response = client.delete_file_system(FileSystemId=self.filesystemid)
            if response['Lifecycle'] == 'DELETING':
                log.info(f'FSx disk {self.filesystemid} is DELETING')
                self.status='deleted'
            else:
                log.info(f'Something went wrong when deleting the FSx disk {self.filesystemid} ... manually check the status')
                self.status='error'

        except ClientError as e:
            log.exception('ClientError exception in AWSScratch.delete. ' + str(e))
            raise signals.FAIL()


    def remote_mount(self, hosts: list):
        """ Mount this FSx disk on remote hosts 

        Parameters
        ----------
        hosts : list of str
          The list of remote hosts
        """

        # TODO: synchronization issue if two new jobs are started at the same time
        #       We need to make sure that the FSx disk is already spun up otherwise this will fail
        log.debug(f"dnsname: {self.dnsname}, mountname: {self.mountname}, mountpath: {self.mountpath}")
        for host in hosts:
            try:
            
                subprocess.run(['ssh', host, 'mkdir', '-p', self.mountpath ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

                result = subprocess.run(['ssh', host, 'sudo', 'mount', '-t', 'lustre', '-o', 'noatime,flock', 
                                        f'{self.dnsname}@tcp:/{self.mountname}', self.mountpath ],
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

                if result.returncode != 0:
                    print(result.stdout)
                    log.exception(f'unable to mount scratch disk on host: {host}')
                    raise signals.FAIL()
            except Exception as e:
                log.exception('unable to mount scratch disk on host...', host)
                traceback.print_stack()
                raise signals.FAIL()
        return


if __name__ == '__main__':
    pass
