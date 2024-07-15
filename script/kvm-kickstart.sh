# This bash script creates a new KVM virtual machine on RHEL with libvirt.
# Machine boots with EFI, not BIOS.
# TTY arguments make "virsh console" work.
# Kickstart file defines many OS things.

# storage values
POOL=images
POOL_DIR=/var/lib/libvirt/libvirt/$POOL
# compute values
HOST=my-new-host
NEW_DISK=/var/lib/libvirt/images/$HOST.qcow2
CPUS=2
MEMORY=4092
DISK_SIZE=20G
# network values
# first network interface
IF1_MAC=52:54:00:00:00:03
IF1_IP=192.168.122.3
IF1_DOMAIN=lab.example.com
IF1_BRIDGE=virbr0
# second network interface
IF2_MAC=52:54:00:00:01:03
IF2_IP=192.168.152.3
IF2_DOMAIN=private.example.com
IF2_BRIDGE=virbr1
# OS values
INSTALL_ISO=/var/lib/libvirt/images/rhel-8.3-x86_64-dvd.iso
KICKSTART_CONFIG=/root/libvirt/$HOST.ks
OS_VARIANT=rhel8.2


# create a new VM
# one network interface
if [ -z $IF2_IP ] ; then 
  virt-install \
    --network    bridge:${IF1_BRIDGE},mac=$IF1_MAC   \
    --name       $HOST.$IF1_DOMAIN \
    --vcpus      $CPUS \
    --ram        $MEMORY \
    --disk       path=$NEW_DISK,size=$DISK_SIZE \
    --os-variant $OS_VARIANT \
    --boot       uefi,hd,menu=on \
    --location   $INSTALL_ISO \
    --initrd-inject $KICKSTART_CONFIG \
    --extra-args "inst.ks=file:/$HOST.ks console=tty0 console=ttyS0,115200" \
    --noautoconsole
else 
# two network interfaces
  virt-install   \
    --network    bridge:${IF1_BRIDGE},mac=$IF1_MAC   \
    --network    bridge:${IF2_BRIDGE},mac=$IF2_MAC   \
    --name       $HOST.$IF1_DOMAIN \
    --vcpus      $CPUS \
    --ram        $MEMORY \
    --disk       path=$NEW_DISK,size=$DISK_SIZE \
    --os-variant $OS_VARIANT \
    --boot       uefi,hd,menu=on \
    --location   $INSTALL_ISO \
    --initrd-inject $KICKSTART_CONFIG \
    --extra-args "inst.ks=file:/$HOST.ks console=tty0 console=ttyS0,115200" \
    --noautoconsole
fi


# customize the hypervisor
# add host DNS
# echo "$IF1_IP   $HOST" >> /etc/hosts
