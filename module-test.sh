#!/usr/bin/env bash

DEFAULT_IMAGE="quay.io/cloudnativetoolkit/cli-tools:v1.2-v2.4.1"
DEFAULT_DOCKER_CMD="docker"

displayUsage() {
  echo "Launches and attaches to a docker container for testing a supplied module sub-directory."
  echo
  echo "Usage: $0 -m MODULE_DIR -v TFVAR_FILE -c CREDENTIALS_FILE [-i IMAGE] [-d DOCKER_CMD]"
  echo " options:"
  echo " m     the directory containing the module to be tested"
  echo " v     the full path to the terraform.tfvar file to be used"
  echo " c     credentials file path"
  echo " i     (optional) the container image to be used"
  echo " d     (optional) the docker command to be used"
  echo " h     Print this help"
  echo
}

# Get command line options
while getopts ":m:v:c:i:d:h" option; do
  case $option in
    h) # Display help
      displayUsage
      exit 1;;
    m) # module path
      MODULE_DIR=$OPTARG;;
    v) # terraform file
      TFVAR_FILE=$OPTARG;;
    c) # credentials file
      CRED_FILE=$OPTARG;;
    i) # image
      IMAGE=$OPTARG;;
    d) # docker command
      DOCKER_CMD=$OPTARG;;
    \?) # Invalid option
      echo "Error: Invalid option"
      displayUsage
      exit 1;;
  esac
done

# Check if module directory exists
if [[ ! -d ${MODULE_DIR} ]]; then
  echo "Error: Invalid module directory ${MODULE_DIR}"
  exit 1
fi

# Check if tfvar file exists
if [[ ! -f ${TFVAR_FILE} ]]; then
  echo "Error: ${TFVAR_FILE} not found"
  exit 1
fi

# Check if different docker command entered
if [[ ! -n $DOCKER_CMD ]]; then
  DOCKER_CMD=$DEFAULT_DOCKER_CMD
fi

# Use default image if none provided
if [[ -z $IMAGE ]]; then
    DOCKER_IMAGE=${DEFAULT_IMAGE}
else
    DOCKER_IMAGE=${IMAGE}
fi

echo "Using $DOCKER_IMAGE as container image"

SUFFIX=$(echo $(basename ${MODULE_DIR}) | base64 | sed -E "s/[^a-zA-Z0-9_.-]//g" | sed -E "s/.*(.{5})/\1/g")
CONTAINER_NAME="module-test-${SUFFIX}"

echo "Cleaning up old container: ${CONTAINER_NAME}"

${DOCKER_CMD} kill ${CONTAINER_NAME} 1> /dev/null 2> /dev/null
${DOCKER_CMD} rm ${CONTAINER_NAME} 1> /dev/null 2> /dev/null

ENV_FILE=""
if [[ -f "${CRED_FILE}" ]]; then
  ENV_FILE="--env-file ${CRED_FILE}"
else
  echo "Error: Credentials file, ${CRED_FILE}, not found"
  exit 1
fi

echo "Initializing container ${CONTAINER_NAME} from ${DOCKER_IMAGE}"
${DOCKER_CMD} run -itd --name ${CONTAINER_NAME} \
   --device /dev/net/tun --cap-add=NET_ADMIN \
   -v "${MODULE_DIR}:/terraform/module" \
   ${ENV_FILE} \
   -w /tmp/workspace \
   ${DOCKER_IMAGE} 

echo "Copying ${TFVAR_FILE} to container"
${DOCKER_CMD} cp ${TFVAR_FILE} ${CONTAINER_NAME}:/terraform/terraform.tfvars

echo "Copying module setup script to container"
${DOCKER_CMD} cp ./setup.sh ${CONTAINER_NAME}:/terraform

echo "Setting up environment"
${DOCKER_CMD} exec -ti ${CONTAINER_NAME} sh -c "/terraform/setup.sh"

echo "Attaching to running container..."
${DOCKER_CMD} attach ${CONTAINER_NAME}