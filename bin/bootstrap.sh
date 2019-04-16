#!/bin/bash
set -eu
source "$(cd $(dirname "${BASH_SOURCE[0]}") &>/dev/null && pwd)/common.sh"

# install packages
apt install -y build-essential libtool sudo quota net-tools curl git zsh vim emacs nano mle screen tmux irssi weechat inspircd

# configure quota
awk -vq=$quota_path '{if($2==q){ $4=$4",usrjquota=aquota.user,jqfmt=vfsv1" } print}' /etc/fstab >/etc/fstab.new
mv -vf /etc/fstab.new /etc/fstab
mount -vo remount $quota_path
quotacheck -ucm $quota_path
quotaon -v $quota_path

# configure sshd
cp -vf "$rwrs_root/etc/sshd_config" /etc/ssh/
systemctl restart sshd

# configure restricted user slice
mkdir -p $restricted_slice_dir
cp -vf "$rwrs_root/etc/user-restricted.slice.conf" $restricted_slice_dir
systemctl daemon-reload

# configure cron
cp -vf "$rwrs_root/etc/cron" /etc/cron.d/rw-rs

# configure ircd
touch /etc/motd
ln -vfs /etc/motd /etc/inspircd/inspircd.motd
cp -vf "$rwrs_root/etc/inspircd.conf" /etc/inspircd/inspircd.conf
ircd_pass=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24)
sed -i "s/@ircdpasshere@/$ircd_pass/g" /etc/inspircd/inspircd.conf
chown -R irc:irc /etc/inspircd/
chmod 700 /etc/inspircd/
chmod 600 /etc/inspircd/inspircd.conf
systemctl restart inspircd

# TODO tls ircd
# TODO httpd with per-user web dirs
# TODO simple alerting
# TODO smoker tests