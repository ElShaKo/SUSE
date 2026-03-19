#!/bin/bash

#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Fail build on error
#--------------------------------------
set -e

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$kiwi_iname]..."

#======================================
# Setup the build keys
#--------------------------------------
suseImportBuildKey


baseInsertService chronyd
baseInsertService NetworkManager

selinux_config=/etc/selinux/config
if test -e $selinux_config && grep -q '^SELINUX=' $selinux_config ; then
    sed -i -e 's/^SELINUX=.*/SELINUX=enforcing/' $selinux_config
else
    echo "SELINUX=enforcing" >> $selinux_config
fi

profiles="${kiwi_profiles/,/|}"

cat >> "/etc/zypp/locks" <<EOF
type: package
match_type: glob
case_sensitive: on
solvable_name: plymouth*
EOF

# Customize motd per arch
arch=`uname -m`
sed -i "s/MYARCH/$arch/" /etc/motd

[ -x /sbin/set_polkit_default_privs ] && /sbin/set_polkit_default_privs

# Generation of the iscsi config file moved to %post of the package
# This implies that all instances have the same iscsi initiator name as the
# file is generated during image build. We do not want this (bsc#1202540)
rm -rf /etc/iscsi/initiatorname.iscsi

sed -i -e 's/^root:[^:]*:/root:*:/' /etc/shadow

sed -i -e 's/# download.use_deltarpm = true/download.use_deltarpm = false/' \
    /etc/zypp/zypp.conf

sed -i -e 's/latest,latest-1,running/latest,running/' /etc/zypp/zypp.conf

baseInsertService boot.device-mapper
baseInsertService sshd
baseRemoveService boot.efivars
baseRemoveService boot.lvm
baseRemoveService boot.md
baseRemoveService boot.multipath
baseRemoveService display-manager
baseRemoveService kbd
baseRemoveService mdadm
baseRemoveService lvm2-monitor


##
# sudo - devops user
##
cat >> "/etc/sudoers.d/devops" <<EOF
devops ALL=(ALL) NOPASSWD: ALL
EOF


##
# For Azure
##
profiles="${kiwi_profiles/,/|}"
if [[ azure-base =~ ^(${profiles})$ ]]; then
    # Implement password policy
    # Length: 6-72 characters long
    # Contain any combination of 3 of the following:
    #   - a lowercase character
    #   - an uppercase character
    #   - a number
    #   - a special character
    pwd_policy="minlen=6 dcredit=1 ucredit=1 lcredit=1 ocredit=1 minclass=3"
    sed -i -e "s/pam_cracklib.so/pam_cracklib.so $pwd_policy/" \
        /etc/pam.d/common-password-pc

    dc=/etc/dhcpcd.conf
    if grep -qE '^timeout' $dc ; then
        sed -r -i 's/^timeout.*/timeout 300/' $dc
    else
        echo 'timeout 300' >> $dc
    fi

    # Generate all supported SSH host key types
    sed -i -e 's/SshHostKeyPairType=rsa/SshHostKeyPairType=auto/' \
        /etc/waagent.conf

    # Leave the ephemeral disk handling to cloud-init
    sed -i -e 's/ResourceDisk.Format=y/ResourceDisk.Format=n/' \
        /etc/waagent.conf

    # Keep the default kernel log level (bsc#1169201)
    sed -i -e 's/$klogConsoleLogLevel/#$klogConsoleLogLevel/' /etc/rsyslog.conf

    baseInsertService cloud-config
    baseInsertService cloud-final
    baseInsertService cloud-init
    baseInsertService cloud-init-local
    baseInsertService waagent

    systemctl enable cloud-netconfig.timer
fi


##
# For EC2
##
profiles="${kiwi_profiles/,/|}"
if [[ ec2-base =~ ^(${profiles})$ ]]; then
    # No Xen based instance types for ARM, no need for custom config
    if [ "`uname -m`" = "aarch64" ]; then
        rm -f /etc/dracut.conf.d/07-*.conf
    fi

    baseInsertService cloud-config
    baseInsertService cloud-final
    baseInsertService cloud-init
    baseInsertService cloud-init-local
    baseInsertService cloud-init-main
    baseInsertService cloud-init-network

    systemctl enable cloud-netconfig.timer
fi


##
# For GCE
##
profiles="${kiwi_profiles/,/|}"
if [[ gce-base =~ ^(${profiles})$ ]]; then
    cat >> "/etc/boto.cfg" <<EOF
[Boto]
ca_certificates_file = system
EOF
    cat >> "/etc/boto.cfg.template" <<EOF
[Boto]
ca_certificates_file = system
EOF
    cat >> "/etc/default/instance_configs.cfg.distro" <<EOF
[InstanceSetup]
set_boto_config = false
EOF

    baseInsertService google-guest-agent
    baseInsertService google-osconfig-agent
    systemctl enable google-oslogin-cache.timer
    baseInsertService google-shutdown-scripts
    baseInsertService google-startup-scripts

    systemctl enable cloud-netconfig.timer
fi
