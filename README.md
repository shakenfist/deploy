Shaken Fist: Opinionated to the point of being impolite
=======================================================

What is this?
-------------

Shaken Fist is a deliberately minimal cloud. You can read more about Shaken Fist at https://github.com/shakenfist/shakenfist --
this repository is the deployment and CI tooling for the project, and therefore not a great place to start your journey.

Installation
------------

Build an acceptable deployment, noting that only Ubuntu is supported.

On Google Cloud, you need to enable nested virt first:

```bash
# Create an image with nested virt enabled (only once)
gcloud compute disks create sf-source-disk --image-project ubuntu-os-cloud \
    --image-family ubuntu-1804-lts --zone us-central1-b
gcloud compute images create sf-image \
  --source-disk sf-source-disk --source-disk-zone us-central1-b \
  --licenses "https://compute.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"
```

Update the contents of ansible/vars with locally valid values. Its a YAML file if that helps.

The ansible takes varying variables depending on your undercloud provider. Here's a handy dandy table:

| Cloud                 | Variables                      | Example               |
|-----------------------|--------------------------------|-----------------------|
| Google Compute Engine | Your google compute project ID | -var project=foo-1234 |
|-----------------------|--------------------------------|-----------------------|

Now create your database and hypervisor nodes (where foo-1234 is my Google Compute project):

```bash
sudo apt-get install ansible tox pwgen
git clone https://github.com/shakenfist/deploy
cd deploy/ansible
ansible-galaxy install andrewrothstein.etcd-cluster
ansible-playbook -i ansible/hosts-gcp $VARIABLES_AS_ABOVE ansible/deploy.yml
```