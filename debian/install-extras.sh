#!/bin/bash
set -e

source common/ui.sh
source common/utils.sh

info 'Installing extra packages and upgrading'

debug 'Bringing container up'
utils.lxc.start

# Sleep for a bit so that the container can get an IP
SECS=5
log "Sleeping for $SECS seconds..."
sleep $SECS

info 'Setting nameserver'
echo "nameserver 8.8.8.8" >> /var/lib/lxc/${CONTAINER}/rootfs/etc/resolvconf/resolv.conf.d/head
#utils.lxc.attach "echo nameserver 8.8.8.8 >> /etc/resolvconf/resolv.conf.d/head"
utils.lxc.attach resolvconf -u

PACKAGES=(vim curl wget man-db openssh-server bash-completion ca-certificates sudo)

log "Installing additional packages: ${ADDPACKAGES}"
PACKAGES+=" ${ADDPACKAGES}"

if [ $DISTRIBUTION = 'ubuntu' ]; then
  PACKAGES+=' software-properties-common'
fi
if [ $RELEASE != 'raring' ] && [ $RELEASE != 'saucy' ] && [ $RELEASE != 'trusty' ] && [ $RELEASE != 'wily' ] ; then
  PACKAGES+=' nfs-common'
fi
if [ $RELEASE != 'stretch' ] ; then
  PACKAGES+=' python-software-properties'
fi
utils.lxc.attach apt-get update
utils.lxc.attach apt-get install ${PACKAGES[*]} -y --force-yes
utils.lxc.attach apt-get upgrade -y --force-yes

if [ $DISTRIBUTION == 'ubuntu' ] && [ $RELEASE = 'xenial' ]; then
  utils.lxc.attach "systemctl enable ssh.socket"
fi

if [ $DISTRIBUTION = 'debian' ]; then
  # Enable bash-completion
  sed -e '/^#if ! shopt -oq posix; then/,/^#fi/ s/^#\(.*\)/\1/g' \
    -i ${ROOTFS}/etc/bash.bashrc
fi
