#!/usr/bin/env python3

import sys
import traceback

import boto3
from botocore.exceptions import ClientError

DEBUG=True

def main():

    ''' AMI names must be between 3 and 128 characters long, and may contain letters, numbers, 
       '(', ')', '.', '-', '/' and '_'
    '''
    lenargs = len(sys.argv) - 1
    if lenargs == 3:
      instance_id = sys.argv[1]
      image_name = sys.argv[2]
      project_tag = sys.argv[3]
    else:
      print(f"Usage: {sys.argv[0]} <instance_id> <image_name> <project_tag>")
      sys.exit(1)

    #print (f"DEBUG: instance_id: {instance_id}, image_name: {image_name}, project_tag: {project_tag}")


    print("Creating a snapshot of current root volume ...")
    snapshot_id = create_snapshot(instance_id, image_name, project_tag)
    if snapshot_id == None:
      print("ERROR: could not create snapshot")
      sys.exit(1)

    print(f"snapshot_id: {snapshot_id}")

    print("Creating AMI from snapshot ...")
    image_id  = create_image_from_snapshot(snapshot_id, image_name)
    print("image_id: ", str(image_id))


def create_snapshot(instance_id: str, name_tag: str, project_tag: str):
  ''' NOTE: Run 'sync' on filesystem to flush the disk cache before running this ''' 

  # print(f"create_snapshot: instance_id: {instance_id}, name_tag: {name_tag}, project_tag: {project_tag}")

  ec2 = boto3.client('ec2', region_name='us-east-2')

  description = f"Created by IOOS Cloud Sandbox for AMI"
  try: 
    response = ec2.create_snapshots(
      Description=description,
      InstanceSpecification={
          'InstanceId': instance_id,
          'ExcludeBootVolume': False
      },
      TagSpecifications=[
          {
              'ResourceType': 'snapshot',
              'Tags': [
                  { 'Key': 'Name', 'Value': name_tag },
                  { 'Key': 'Project', 'Value': project_tag }
              ]
          }
      ],
      DryRun=False
      # CopyTagsFromSource='volume'
    )
  except Exception as e:
    print(str(e))
    traceback.print_stack()
    return None

  snapshot_id = response['Snapshots'][0]['SnapshotId']
  return snapshot_id


def create_image_from_snapshot(snapshot_id: str, image_name: str):
  print(f"create_image_from_snapshot: snapshot_id: {snapshot_id}, image_name: {image_name}")

  # image_name needs to be unique
  # Region must be defined in AWS_DEFAULT_REGION env var

  region_name = 'us-east-2'
  ec2 = boto3.client('ec2', region_name='us-east-2' )
  #ec2 = boto3.client('ec2')

  description = f"Created by IOOS Cloud Sandbox from snapshot: {snapshot_id}"

  root_mapping = {
    'DeviceName': '/dev/sda1',
    'Ebs': {
      'DeleteOnTermination': True,
      'SnapshotId': snapshot_id,
      'VolumeType': 'gp2'
    }
  }

  try:
    resrc = boto3.resource('ec2')
    snapshot = resrc.Snapshot(snapshot_id)

    # Wait for snapshot to be created 
    # wait_until will throw an exception after 10 minutes
    maxtries=5
    tries=1
    while tries <= maxtries:
      print(f"Waiting for snapshot creation ...")
      try:
      
        snapshot.wait_until_completed()
        break
      except Exception as e:
        print("WARNING: " + str(e))
        tries += 1
        #print(f"... waiting for snapshot creation: tries {tries} of {maxtries}")

        if tries == maxtries:
          print("ERROR: maxtries reached. something went wrong")
          traceback.print_stack()
          # return None

  except Exception as e:
    print("Exception: " + str(e))
    if DEBUG: traceback.print_stack()
    return None  
 
  response=''
  try:
    response = ec2.register_image(
      Architecture='x86_64',
      BlockDeviceMappings=[ root_mapping ],
      Description=description,
      #DryRun=True,
      EnaSupport=True,
      Name=image_name,
      RootDeviceName='/dev/sda1',
      VirtualizationType='hvm'
    )
  except Exception as e:
    print("Exception: " + str(e))
    if DEBUG: traceback.print_stack()
    return None

  image_id = response['ImageId']

  # Give it a Name tag also
  ec2.create_tags(
    Resources=[ image_id ],
    Tags=[ { 'Key': 'Name',
             'Value': image_name } ])

  return image_id

#####################################################################
if __name__ == '__main__':
    main()
