#!/bin/bash -x
# This bash script creates a new KVM virtual machine on RHEL with libvirt.
# Machine boots with EFI, not BIOS.
# TTY arguments make "virsh console" work.
# Kickstart file defines many OS things.

# validate 
# https://access.redhat.com/solutions/2132051
# dnf install pykickstart
# ksvalidator -v RHEL7  ./rhel7.lab.example.com.ks 

HOST=rhel7
# network values
# first network interface
IF1_MAC=52:54:00:00:00:03
IF1_DOMAIN=lab.example.com
IF1_BRIDGE=virbr0
# second network interface
# IF2_MAC=52:54:00:00:01:03
# IF2_DOMAIN=private.example.com
# IF2_BRIDGE=virbr1
# OS values
FQDN=$HOST.$IF1_DOMAIN
KICKSTART_CONFIG=/root/libvirt/$FQDN.ks
OS_VARIANT=rhel7.9
# storage values
POOL=images
POOL_DIR=/var/lib/libvirt/$POOL
INSTALL_ISO=/var/lib/libvirt/images/rhel-server-7.9-x86_64-dvd.iso
NEW_DISK=/var/lib/libvirt/images/$FQDN.qcow2
# compute values
CPUS=2
MEMORY=4092
DISK_SIZE=30


# create a new VM
# one network interface
#    --boot       uefi,hd,menu=on \

  virt-install \
    --network    bridge:${IF1_BRIDGE},mac=$IF1_MAC   \
    --name       $FQDN \
    --vcpus      $CPUS \
    --ram        $MEMORY \
    --disk       path=$NEW_DISK,size=$DISK_SIZE \
    --os-variant $OS_VARIANT \
    --location   $INSTALL_ISO \
    --initrd-inject $KICKSTART_CONFIG \
    --extra-args "inst.ks=file:/$FQDN.ks console=tty0 console=ttyS0,115200" \
    --noautoconsole

# customize the hypervisor
# add host DNS
# echo "$IF1_IP  $FQDN  $HOST" >> /etc/hosts
