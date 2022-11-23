# module-test-tool
Tool to help test modules locally. This tool allows you to test a module locally to debug prior to pushing to github and running as a github action.

It will start a container and copy the contents of a supplied module directory into a working directory from which you can then run terraform in the same environment as the github action.

The tool has been tested on Linux servers and desktops.

## Prerequisites

- a docker runtime is required

## Instructions

1. Download the tfvar file required for the module (refer to the `.github/workflows/verify*.yaml` for the tfvar file used in the module automated test), or create as needed. You can also find tfvar files used for testing in the `cloud-native/toolkit/action-module-verify` repository [here](https://github.com/cloud-native-toolkit/action-module-verify/tree/main/env)

2. Create a `credentials.properties` file with the required secrets for testing. Several example templates are included in this repository.

3. Clone the module to be tested to a local directory

4. Run `module-setup.sh` and specify the module path, terraform filename and credentials filename. This will download the image, start a container, copy the files from the module into a working directory in the container and attach to the container at that working directory.

For example:
```
$ ./module-test.sh -m /home/richard/github/terraform-ibm-toolkit-ocp-vpc -c ./credentials.properties -v ./terraform.tfvars 
```

The script includes a help option with the following output:
```
$ ./module-test.sh -h
Launches and attaches to a docker container for testing a supplied module sub-directory.

Usage: ./module-test.sh -m MODULE_DIR -v TFVAR_FILE -c CREDENTIALS_FILE [-i IMAGE] [-d DOCKER_CMD]
 options:
 m     the directory containing the module to be tested
 v     the full path to the terraform.tfvar file to be used
 c     credentials file path
 i     (optional) the container image to be used
 d     (optional) the docker command to be used
 h     Print this help
```

5. Run `terraform init` and `terraform apply` or other commands as required.
