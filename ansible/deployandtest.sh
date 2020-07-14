#!/bin/bash -e
#
# ./deployandtest.sh [aws|aws-single-node|gcp|metal|openstack]
#
#
# Note: Tests can be skipped by setting $SKIP_SF_TESTS
#

#### Required settings
CLOUD=${1:-$CLOUD}

#### AWS
if [ "$CLOUD" == "aws" ] || [ "$CLOUD" == "aws-single-node" ]
then
  if [ -z "$AWS_REGION" ]
  then
    echo ===== Must specify AWS region in \$AWS_REGION
    exit 1
  fi
  VARIABLES="$VARIABLES region=$AWS_REGION"

  if [ -z "$AWS_AVAILABILITY_ZONE" ]
  then
    echo ===== Must specify AWS availability zone in \$AWS_AVAILABILITY_ZONE
    exit 1
  fi
  VARIABLES="$VARIABLES availability_zone=$AWS_REGION"

  if [ -z "$AWS_VPC_ID" ]
  then
    echo ===== Must specify AWS VPC ID in \$AWS_VPC_ID
    exit 1
  fi
  VARIABLES="$VARIABLES vpc_id=$AWS_VPC_ID"

  if [ -z "$AWS_SSH_KEY_NAME" ]
  then
    echo ===== Must specify AWS Instance SSH key name in \$AWS_SSH_KEY_NAME
    exit 1
  fi
  VARIABLES="$VARIABLES ssh_key_name=$AWS_SSH_KEY_NAME"
fi

#### Google Cloud
if [ "$CLOUD" == "gcp" ]
then
  if [ -z "$GCP_PROJECT" ]
  then
    echo ===== Must specify GCP project in \$GCP_PROJECT
    exit 1
  fi
  VARIABLES="$VARIABLES project=$GCP_PROJECT"
fi

#### Openstack
if [ "$CLOUD" == "openstack" ]
then
  if [ -z "$OS_SSH_KEY_NAME" ]
  then
    echo ===== Must specify Openstack SSH key name in \$OS_SSH_KEY_NAME
    exit 1
  fi
  VARIABLES="$VARIABLES ssh_key_name=$OS_SSH_KEY_NAME"

  if [ -z "$OS_FLAVOR_NAME" ]
  then
    echo ===== Must specify Openstack instance flavor name in \$OS_FLAVOR_NAME
    exit 1
  fi
  VARIABLES="$VARIABLES os_flavor=$OS_FLAVOR_NAME"

  if [ -z "$OS_EXTERNAL_NET_NAME" ]
  then
    echo ===== Must specify Openstack External network name in \$OS_EXTERNAL_NET_NAME
    exit 1
  fi
  VARIABLES="$VARIABLES os_external_net_name=$OS_EXTERNAL_NET_NAME"
fi

#### Metal
if [ "$CLOUD" == "metal" ]
then
  if [ -z "$METAL_IP_SF1" ]
  then
    echo ===== Must specify the Node 1 machine IP in \$METAL_IP_SF1
    exit 1
  fi
  VARIABLES="$VARIABLES metal_ip_sf1=$METAL_IP_SF1"

  if [ -z "$METAL_IP_SF2" ]
  then
    echo ===== Must specify the Node 2 machine IP in \$METAL_IP_SF2
    exit 1
  fi
  VARIABLES="$VARIABLES metal_ip_sf2=$METAL_IP_SF2"

  if [ -z "$METAL_IP_SF3" ]
  then
    echo ===== Must specify the Node 3 machine IP in \$METAL_IP_SF3
    exit 1
  fi
  VARIABLES="$VARIABLES metal_ip_sf3=$METAL_IP_SF3"
fi


if [ -z "$VARIABLES" ]
then
{
  echo ====
  echo ==== CLOUD should be specified: aws, aws-single-node, gcp, metal, openstack
  echo ==== eg.  ./deployandtest/sh gcp
  echo ====
  echo ==== Continuing, because you might know what you are doing...
  echo
} 2> /dev/null
fi

set -x

#### Default settings
BOOTDELAY="${BOOTDELAY:-2}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Ukoh5vie}"
FLOATING_IP_BLOCK="${FLOATING_IP_BLOCK:-10.10.0.0/24}"
UNIQIFIER="${UNIQIFIER:-$USER"-"`date "+%y%m%d"`"-"`pwgen --no-capitalize -n1`"-"}"


# Setup variables for consumption by ansible and terraform
cwd=`pwd`
TERRAFORM_VARS="-var=uniqifier=$UNIQIFIER"

ANSIBLE_VARS="$ANSIBLE_VARS cloud=$CLOUD"
ANSIBLE_VARS="$ANSIBLE_VARS bootdelay=$BOOTDELAY"
ANSIBLE_VARS="$ANSIBLE_VARS ansible_root=$cwd"
ANSIBLE_VARS="$ANSIBLE_VARS uniqifier=$UNIQIFIER"
ANSIBLE_VARS="$ANSIBLE_VARS ADMIN_PASSWORD=$ADMIN_PASSWORD"
ANSIBLE_VARS="$ANSIBLE_VARS floating_network_ipblock=$FLOATING_IP_BLOCK"

for var in $VARIABLES
do
  TERRAFORM_VARS="$TERRAFORM_VARS -var=$var"
  ANSIBLE_VARS="$ANSIBLE_VARS $var"
done

ansible-playbook -i hosts --extra-vars "$ANSIBLE_VARS" deploy.yml

if [ -e terraform/$CLOUD/local.yml ]
then
  ansible-playbook -i hosts --extra-vars "$ANSIBLE_VARS" terraform/$CLOUD/local.yml
fi

# Old fashioned ansible CI
if [ "%$SKIP_SF_TESTS%" == "%%" ]
then
  ansible-playbook -i hosts --extra-vars "$ANSIBLE_VARS" ../ansible-ci/pretest.yml
  for playbook in `ls ../ansible-ci/tests/test_*.yml | grep -v test_final.yml | shuf`
  do
    ansible-playbook -i hosts --extra-vars "$ANSIBLE_VARS" $playbook
  done

  ansible-playbook -i hosts --extra-vars "$ANSIBLE_VARS" ../ansible-ci/tests/test_final.yml

  # New fangled python CI
  ansible-playbook -i hosts --extra-vars "$ANSIBLE_VARS" test.yml
fi
