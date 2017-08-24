#!/bin/bash

mkdir /etc/ceph

echo "Bringing Ceph configs to devstack node"
scp ceph-primary:/etc/ceph/* /etc/ceph
scp ceph-secondary:/etc/ceph/ceph.conf /etc/ceph/ceph-secondary.conf
scp ceph-secondary:/etc/ceph/ceph.client.admin.keyring /etc/ceph/ceph-secondary.client.admin.keyring
chmod 0600 /etc/ceph/*.client.admin.keyring
chown vagrant:vagrant /etc/ceph/*.client.admin.keyring

echo "Copying ceph-primary config to the secondary"
scp /etc/ceph/ceph.conf ceph-secondary:/etc/ceph/ceph-primary.conf
scp /etc/ceph/ceph.client.admin.keyring ceph-secondary:/etc/ceph/ceph-primary.client.admin.keyring
ssh ceph-secondary 'chmod 0600 /etc/ceph/ceph-primary.client.admin.keyring; chown ceph:ceph /etc/ceph/ceph-primary.client.admin.keyring'

echo "Copying ceph-secondary config to the primary"
scp /etc/ceph/ceph-secondary.conf ceph-primary:/etc/ceph
scp /etc/ceph/ceph-secondary.client.admin.keyring ceph-primary:/etc/ceph
ssh ceph-primary 'chmod 0600 /etc/ceph/ceph-secondary.client.admin.keyring; chown ceph:ceph /etc/ceph/ceph-secondary.client.admin.keyring'
