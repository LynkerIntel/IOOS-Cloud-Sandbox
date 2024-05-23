set -e
source TFOverrides.sh # Could be empty or noop
WORK=${WORK:-"$(realpath ../target)"}
if [ -d ${WORK} ]; then
  echo "Working directory ${WORK} exists."
else
  echo "Working directory ${WORK} does not exist.  Creating."
  mkdir -p ${WORK}
fi

KEYSOURCEFILE=${KEYSOURCEFILE:=${WORK}/${USER}-key-source.sh}
if [ -f ${KEYSOURCEFILE} ]; then # At least try for idempotency
  echo "Key sourcefile ${KEYSOURCEFILE} exists.  Skipping."
  exit 99
fi

KEYNAME=${KEYNAME:-"${USER}-ioos-csb"}
KEYFILE=${KEYFILE:-"${WORK}/${KEYNAME}.pem"}
KEYFILEPUB=${KEYFILEPUB:-"${WORK}/${KEYNAME}.pub"}
if [ -f ${KEYFILE} ]; then # At least try for idempotency
  echo "Key file ${KEYFILE} exists. Skipping."
else
  source ./config.s3.tfbackend # Works as long as there are no TF-interpolated variables in the file
  echo aws ec2 create-key-pair --region=\"${region}\" --key-name \"${KEYNAME}\" --query \"KeyMaterial\" --output text
  aws ec2 create-key-pair --region="${region}" --key-name "${KEYNAME}" --query "KeyMaterial" --output text >${KEYFILE}
  chmod 600 ${KEYFILE}
fi
if [ -f ${KEYFILEPUB} ]; then # At least try for idempotency
  echo "Key file ${KEYFILEPUB} exists. Skipping."
else
  ssh-keygen -y -f ${KEYFILE} >${KEYFILEPUB}
  chmod 644 ${KEYFILEPUB}
fi
echo "keypair exists: ${KEYNAME}.pem and ${KEYNAME}.pub"

echo "# KEYSOURCE FILE FOR ${USER}" >${KEYSOURCEFILE}
echo "export MYKEY=\"$(cat ${KEYFILE})\"" >>${KEYSOURCEFILE}
echo "export MYPUB=\"$(cat ${KEYFILEPUB})\"" >>${KEYSOURCEFILE}
echo "export MYKEYFILE=$(realpath ${KEYFILE})" >>${KEYSOURCEFILE}
echo "export MYPUBFILE=$(realpath ${KEYFILEPUB})" >>${KEYSOURCEFILE}

echo -n "export MYKEY2=\"" >>${KEYSOURCEFILE}
while read line; do
  echo -n "${line}" >>${KEYSOURCEFILE}
  echo "\\" >>${KEYSOURCEFILE}
done <${KEYFILE}
# for a in $(cat ${KEYFILE} ); do echo -n "${a}"; echo -n "\\"; echo -n "\\n"; done >>${KEYSOURCEFILE}
echo "\"" >>${KEYSOURCEFILE}

chmod 600 ${KEYSOURCEFILE}

echo "Created key source file ${KEYSOURCEFILE}"
