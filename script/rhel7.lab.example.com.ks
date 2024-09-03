# kickstart file
# Kickstart guide is here.
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/performing_an_advanced_rhel_9_installation/kickstart-commands-and-options-reference_installing-rhel-as-an-experienced-user#kickstart-commands-for-system-configuration_kickstart-commands-and-options-reference
# This tool creates a kickstart file. 
# https://access.redhat.com/labs/kickstartconfig/

# command section
# -----------------------------------

# install
# System authorization information
auth --enableshadow --passalgo=sha512
# don't use graphical install
text
# look for an installer DVD
cdrom
# Run the Setup Agent on first boot
firstboot --enable
# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=vda

# l10n (localization)
lang en_GB.UTF-8
timezone Europe/London --isUtc
keyboard --vckeymap=gb --xlayouts='gb'

# network
# dynamic IP address
network  --bootproto=dhcp --device=eth0 --ipv6=auto --activate
network  --hostname=rhel7.lab.example.com

# licences and repos
# And have a look at the "subscription" section, in the post section below. 
#repo --name="AppStream" --baseurl=file:///run/install/repo/AppStream
eula --agreed

# accounts
# from the Ansible vault
# These commands set up password-based login.
# To create an encrypted password, try this. 
#   Generate a salt. This command displays 16 printable characters.
#     cat /dev/urandom | tr -dc 'A-Za-z0-9.\_\-+'  | head -c 16
#   Pick a password.
#   Replace 'G3GIlnUH.JqcrAQl' and 'Password;1' with the new salt and password.
#   Run.
#     /usr/bin/openssl passwd  -6 --salt='G3GIlnUH.JqcrAQl' 'Password;1'
# For key-based login, check out 'sshkey --username=user "ssh_key"'.
# For changing a password in the "post" section, try one of these.
#   echo "ansible_user:Password;1" | chpasswd
#   echo "Password;1" | passwd --stdin ansible_user
#
rootpw                                  --iscrypted "$6$G3GIlnUH.JqcrAQl$I.q7gGoT37tcNnrGiHkeUTBtr8AAuoM/yy3P3FuEpJaSun6clgR8GlvKIbqOTgqNe.fIBV6xZOPiWvsduhXeC/"
user --groups=wheel --name=nick          --password="$6$G3GIlnUH.JqcrAQl$I.q7gGoT37tcNnrGiHkeUTBtr8AAuoM/yy3P3FuEpJaSun6clgR8GlvKIbqOTgqNe.fIBV6xZOPiWvsduhXeC/" --iscrypted --gecos=nick
user --groups=wheel --name=ansible_user  --password="$6$G3GIlnUH.JqcrAQl$I.q7gGoT37tcNnrGiHkeUTBtr8AAuoM/yy3P3FuEpJaSun6clgR8GlvKIbqOTgqNe.fIBV6xZOPiWvsduhXeC/" --iscrypted --gecos=ansible_user

# storage 
# Define three partitions.
# Partitions fit in a storage volume of 30 GiB.
#
# partitions
# 1 for /boot/efi                 600M
# 2 for /boot                     1024M
# 3 LVM Physical Volume           8G + 4G = 12G. Add 1, 13G * 1024 = 13312 M
#   LVM logical volume for /root  8G * 1024 = 8192
#   LVM logical volume for /var   4G * 1024 = 4096
#   LVM volume for swap: 256M
#   snapshots
#   double the size of the physical volume
#   13312M * 2 = 26624M
#
ignoredisk --only-use=vda
clearpart --all --initlabel
# part /boot/efi --fstype="efi"   --ondisk=vda --size=600 --fsoptions="umask=0077,shortname=winnt"
part /boot     --fstype="xfs"   --ondisk=vda --size=1024
part pv.03     --fstype="lvmpv" --ondisk=vda --size=26624
volgroup rhel pv.03
logvol /       --fstype="xfs"  --size=8192  --name=root --vgname=rhel
logvol /var    --fstype="xfs"  --size=4096  --name=var  --vgname=rhel
logvol swap    --fstype="swap" --size=256    --name=swap --vgname=rhel

# applications and services 
# Do not configure the X Window System
skipx
services --enabled="chronyd"
selinux --enforcing
# open firewall
# firewall --enabled --service=sshd --service=cockpit

# after installing the OS
# skip anaconda's prompt "Installation complete. Press ENTER to quit:"
reboot

# extra sections 
# -----------------------------------

# package selection section
# guide: 
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9-beta/html/managing_software_with_yum/index
%packages
# This is an environment group of packages.
# View the full list of groups to choose from by running this command.
#   dnf group list --hidden
@^minimal
@core
# single package
chrony
kexec-tools
# These packages provide a selection of sysadmin tools for manual work.
bash-completion
bind-utils
cockpit
lsof
mlocate
nmap
nmap-ncat
vim
tcpdump
telnet
tmux
tree
whois
%end

# add-on section
# kdump kernel crash dump mechanism
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9-beta/html-single/performing_an_advanced_rhel_installation/index#addon-com_redhat_kdump_kickstart-commands-for-addons-supplied-with-the-rhel-installation-program
%addon com_redhat_kdump --enable --reserve-mb='auto'
%end
#

# https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/installation_guide/commands-for-anaconda
# deprecated in RHEL9
# https://access.redhat.com/solutions/7032176
%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

# last jobs
%post --log=/root/ks-post.log

# !!! put this in a loop
# admin user
# key-based login
mkdir -m0700 /home/nick/.ssh/
cat <<EOF >/home/nick/.ssh/authorized_keys
ssh-rsa AAAA...XqgP nick@workstation
EOF
# fix ownership and permissions
chown -R nick:nick /home/nick/.ssh
chmod 0600 /home/nick/.ssh/authorized_keys
# fix up selinux context
restorecon -vR /home/nick/.ssh/
# Allow passwordless sudo.
echo "nick      ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/nick
# CLI prompt. Also see "better_prompt" here:
# https://github.com/nickhardiman/ansible-playbook-aap2-refarch/blob/main/files/aap-bootstrap-1-ssh-sudo.sh
echo "PS1='[\u@\H \W]$ '" >> /home/nick/.bashrc

# root user
# key-based login
mkdir -m0700 /root/.ssh/
cat <<EOF >/root/.ssh/authorized_keys
ssh-rsa AAAA...XqgP nick@workstation
EOF
chmod 0600 /root/.ssh/authorized_keys
# fix up selinux context
restorecon -vR /root/.ssh/
# CLI prompt. Also see "better_prompt" here:
# https://github.com/nickhardiman/ansible-playbook-aap2-refarch/blob/main/files/aap-bootstrap-1-ssh-sudo.sh
echo "PS1='[\u@\H \W]$ '" >> /root/.bashrc

# cockpit
systemctl enable cockpit.socket

%end
