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
