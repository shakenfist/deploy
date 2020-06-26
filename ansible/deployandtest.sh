#!/bin/bash -ex

cwd=`pwd`
TERRAFORM_VARS="-var=uniqifier=$UNIQIFIER"
ANSIBLE_VARS="cloud=$CLOUD bootdelay=$BOOTDELAY ansible_root=$cwd uniqifier=$UNIQIFIER"
for var in $VARIABLES
do
  TERRAFORM_VARS="$TERRAFORM_VARS -var=$var"
  ANSIBLE_VARS="$ANSIBLE_VARS $var"
done

ansible-playbook -i hosts --extra-vars "$ANSIBLE_VARS" deploy.yml
ansible-playbook -i hosts --extra-vars "$ANSIBLE_VARS" test.yml