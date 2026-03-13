#!/bin/bash
# 
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

mkdir /var/lib/misc/reconfig_system

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$name]..."

#======================================
# add missing fonts
# Systemd controls the console font now
#--------------------------------------
echo FONT="eurlatgr.psfu" >> /etc/vconsole.conf

#======================================
# prepare for setting root pw, timezone
#--------------------------------------
echo ** "reset machine settings"

rm -f /etc/machine-id \
      /var/lib/zypp/AnonymousUniqueId \
      /var/lib/systemd/random-seed \
      /var/lib/dbus/machine-id

echo "** Running ldconfig..."
/sbin/ldconfig

#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct

#======================================
# Specify default runlevel
#--------------------------------------
baseSetRunlevel 3

#======================================
# Add missing gpg keys to rpm
#--------------------------------------
suseImportBuildKey

#======================================
# Enable DHCP on eth0
#--------------------------------------
# cat >/etc/sysconfig/network/ifcfg-eth0 <<EOF
# BOOTPROTO='dhcp'
# MTU=''
# REMOTE_IPADDR=''
# STARTMODE='auto'
# ETHTOOL_OPTIONS=''
# USERCONTROL='no'
# EOF

#======================================
# Remove doc files
#--------------------------------------
# rm -rf /usr/share/doc/*
# rm -rf /usr/share/man/man*/*

#======================================
# Sysconfig Update
#--------------------------------------
echo '** Update sysconfig entries...'

# baseUpdateSysConfig /etc/sysconfig/network/dhcp DHCLIENT_SET_HOSTNAME yes

# Enable firewalld if installed
if [ -x /usr/sbin/firewalld ]; then
    systemctl enable firewalld
fi

# Set GRUB2 to boot graphically (bsc#1097428)
sed -Ei"" "s/#?GRUB_TERMINAL=.+$/GRUB_TERMINAL=gfxterm/g" /etc/default/grub
sed -Ei"" "s/#?GRUB_GFXMODE=.+$/GRUB_GFXMODE=auto/g" /etc/default/grub

# On x86 UEFI machines use linuxefi entries
if [[ "$(uname -m)" =~ i.86|x86_64 ]];then
    echo 'GRUB_USE_LINUXEFI="true"' >> /etc/default/grub
fi

#======================================
# SSL Certificates Configuration
#--------------------------------------
echo '** Rehashing SSL Certificates...'
update-ca-certificates

if [ ! -s /var/log/zypper.log ]; then
	> /var/log/zypper.log
fi

#=====================================
# Enable chrony if installed
#-------------------------------------
# if [ -f /etc/chrony.conf ]; then
#     systemctl enable chronyd.service
# fi

# only for debugging
#systemctl enable debug-shell.service

exit 0