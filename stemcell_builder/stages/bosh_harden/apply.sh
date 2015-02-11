#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

# We really want to lock these down - but we're having issues
# with both our components and users apps assuming this is writable
# Tempfile and friends - we'll punt on this for 4/12 and revisit it
# in the immediate release cycle after that.
# Lock dowon /tmp and /var/tmp - jobs should use /var/vcap/data/tmp
chmod 0770 $chroot/tmp $chroot/var/tmp

# remove setuid binaries - except su/sudo (sudoedit is hardlinked)
run_in_bosh_chroot $chroot "
find / -xdev -perm +6000 -a -type f \
  -a -not \( -name sudo -o -name su -o -name sudoedit \) \
  -exec chmod ug-s {} \;
"

# No root ssh
sed "/^ *PermitRootLogin/d" -i $chroot/etc/ssh/sshd_config
echo 'PermitRootLogin no' >> $chroot/etc/ssh/sshd_config

# Disallow CBC Ciphers
sed "/^ *Ciphers/d" -i $chroot/etc/ssh/sshd_config
echo 'Ciphers arcfour,arcfour128,arcfour256,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com' >> $chroot/etc/ssh/sshd_config

# Disallow Weak MACs
sed "/^ *MACs/d" -i $chroot/etc/ssh/sshd_config
echo 'MACs hmac-sha1,hmac-sha2-256,hmac-sha2-512,hmac-ripemd160,hmac-ripemd160@openssh.com,umac-64@openssh.com,umac-128@openssh.com,hmac-sha1-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-ripemd160-etm@openssh.com,umac-128-etm@openssh.com' >> $chroot/etc/ssh/sshd_config
