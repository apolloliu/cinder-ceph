# OpenStack admin auth
source /opt/stack/devstack/openrc admin admin

echo "Deleting cinder users on the secondary cluster"
sudo ceph --cluster ceph-secondary del client.cinder
sudo ceph --cluster ceph-secondary del client.cinder-bak

echo "Deleting Ceph 'volumes' pool on the secondary cluster"
sudo ceph --cluster ceph-secondary osd pool delete volumes volumes --yes-i-really-really-mean-it

echo "Creating 'volumes' pool on the secondary cluster"
sudo ceph --cluster ceph-secondary osd pool create volumes 100

echo "Enabling Ceph per-image mirroring on volumes pools"
sudo rbd mirror pool enable volumes image
sudo rbd --cluster ceph-secondary mirror pool enable volumes image

echo "Peering both Ceph clusters for mirroring"
sudo rbd mirror pool peer add volumes client.admin@ceph-secondary
sudo rbd mirror pool peer add volumes client.admin@ceph-primary --cluster ceph-secondary

echo "Creating cinder user on the secondary cluster"
sudo ceph auth get client.cinder -o /etc/ceph/ceph.client.cinder.keyring
sudo chmod 0600 /etc/ceph/ceph.client.cinder.keyring
sudo chown stack:stack /etc/ceph/ceph.client.cinder.keyring
sudo ceph --cluster ceph-secondary auth import -i /etc/ceph/ceph.client.cinder.keyring
sudo cp -p /etc/ceph/ceph.client.cinder.keyring /etc/ceph/ceph-secondary.client.cinder.keyring

echo "Creating Cinder Ceph replicated volume type"
cinder type-create replicated
cinder type-key    replicated set volume_backend_name=ceph
cinder type-key    replicated set replication_enabled='<is> True'
