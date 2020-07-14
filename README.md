Shaken Fist: Opinionated to the point of being impolite
=======================================================

What is this?
-------------

Shaken Fist is a deliberately minimal cloud. You can read more about Shaken Fist at https://github.com/shakenfist/shakenfist --
this repository is the deployment and CI tooling for the project, and therefore not a great place to start your journey.

Installation
------------

Build an acceptable deployment, noting that only Ubuntu is supported.

## Common first steps

```bash
sudo apt-get install ansible tox pwgen
git clone https://github.com/shakenfist/deploy
cd deploy
git submodule init
git submodule update
cd ansible
ansible-galaxy install andrewrothstein.etcd-cluster
```

## Google Cloud

On Google Cloud, you need to enable nested virt first:

```bash
# Create an image with nested virt enabled (only once)
gcloud compute disks create sf-source-disk --image-project ubuntu-os-cloud \
    --image-family ubuntu-1804-lts --zone us-central1-b
gcloud compute images create sf-image \
  --source-disk sf-source-disk --source-disk-zone us-central1-b \
  --licenses "https://compute.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"
```

Configure deployment parameters and deploy

```bash
cd ansible
export METAL_IP_SF1="192.168.72.240"
export METAL_IP_SF2="192.168.72.230"
export METAL_IP_SF3="192.168.72.242"
./deployandtest.sh
```

## OpenStack Deployment

Configure deployment parameters and deploy

```bash
cd ansible
export OS_SSH_KEY_NAME="and-arwen"
export OS_FLAVOR_NAME="2C-4GB-50GB"
export OS_EXTERNAL_NET_NAME="ext-net"
./deployandtest.sh
```

## Bare Metal Deployment

Configure deployment parameters and deploy

```bash
cd ansible
export METAL_IP_SF1="192.168.72.240"
export METAL_IP_SF2="192.168.72.230"
export METAL_IP_SF3="192.168.72.242"
./deployandtest.sh
```

### VMWare ESXi

The "metal" installation option can be used to create a test cluster on VMWare ESXi hypervisors.

Virtual machines hosted under ESXi need two CPU options enabled.

```
Hardware virtualization:
    Expose hardware assisted virtualization to the guest OS

Performance counters:
    Enable virtualized CPU performance counters
```
