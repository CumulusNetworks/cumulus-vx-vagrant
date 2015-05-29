#!/bin/bash
set -e

# Create & configure a suitable vagrant user
function create_vagrant_user
{
  echo "Creating vagrant user"

  # Create "vagrant" user with password set to "vagrant"
  HOMEDIR=/home/vagrant
  PASSWD="\$6\$fDzSgbx66\$VjmM6avPa8qVWZWTjJKrfh6bulZjs6ivU/dy7Kfox3Ox2sPQBmTzR1enNI/N0mVv83VTVP2VPPtHciRY0MRMv1"
  useradd -m -d $HOMEDIR -s /bin/bash -G sudo -p "$PASSWD" vagrant

  # Add vagrant public SSH key
  mkdir -p $HOMEDIR/.ssh
  cat << _EOF > $HOMEDIR/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
_EOF

  chown -R vagrant:vagrant $HOMEDIR/.ssh
  chmod 0700 $HOMEDIR/.ssh
  chmod 0600 $HOMEDIR/.ssh/authorized_keys
}

# Install the VirtualBox guest additions
function install_guest_additions
{
  echo "Installing VirtualBox guest additions"
  HOMEDIR=/home/cumulus
  ISO="$HOMEDIR/VBoxGuestAdditions.iso"
  VBOX="$HOMEDIR/vbox"
  if [ -e "$ISO" ]
  then
    # Mount guest additions ISO (provided by Packer)
    mkdir "$VBOX"
    mount -o loop "$ISO" "$VBOX"

    # Install
    sh "$VBOX/VBoxLinuxAdditions.run"

    # Clean up
    umount "$VBOX"
    rmdir "$VBOX"
    rm "$ISO"
  else
    echo "Missing VBoxGuestAdditions.iso!"
    exit 1
  fi
}

# Install Puppet client
function install_puppet
{
  VERSION="$1"
  echo "Installing Puppet $VERSION"
  apt-get update
  apt-get install -y puppet=$VERSION 
}

# Install Chef client
function install_chef
{
  VERSION="$1"
  echo "Installing Chef $VERSION"
  apt-get update
  apt-get install -y chef=$VERSION 
}

# Defaults
WANT_VAGRANT_USER=1
WANT_VBOX_ADDITIONS=0 # XXX Currently doesn't work; no loop device support
INSTALL_PUPPET=0
PUPPET_VERSION=""
INSTALL_CHEF=0
CHEF_VERSION=""

# Select configuration
# XXX getopt
INSTALL_PUPPET=1
INSTALL_CHEF=1
# Normally the puppet & chef versions would be selected according to which version of cumulus + flags
PUPPET_VERSION="3.6.2-1puppetlabs1"
CHEF_VERSION="11.6.2-1"

# Perform configuration
if [ $WANT_VAGRANT_USER -ne 0 ]
then
  create_vagrant_user
fi 
if [ $WANT_VBOX_ADDITIONS -ne 0 ]
then
  install_guest_additions
fi
if [ $INSTALL_PUPPET -ne 0 ]
then
  install_puppet "$PUPPET_VERSION"
fi
if [ $INSTALL_CHEF -ne 0 ]
then
  install_chef "$CHEF_VERSION"
fi

exit 0
