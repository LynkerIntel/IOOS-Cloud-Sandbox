SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
USER=malvis
CHECKOUT=$(realpath $SCRIPT_DIR)
WORK=${CHECKOUT}/target
ALLOWED_SSH_CIDR="$(curl ipinfo.io/ip)/32"
# What's this?  Are you insane?
# key_name | "your-key-pair" | The key pair generated in the prior step |
# public_key | "ssh-rsa your_public_key" | The public key obtained in the prior step. Must include "ssh-rsa", assuming it is an rsa key |
# vpc_id | "vpc- your_vpc_id" | The ID of an existing VPC for Terraform to use for deployment |
# subnet_id | "subnet- your_subnet_id" | The ID of an existing Subnet for Terraform to use for deployment |
