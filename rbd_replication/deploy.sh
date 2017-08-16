
#!/bin/bash

my_ip=192.168.111.141
hostname=`hostname -s`

cd /root

echo "Installing ceph-deploy from pip to avoid existing package conflict"
yum update

yum -y install epel-release
yum install -y python-pip
pip install --upgrade pip

pip install ceph-deploy

echo "Creating cluster"
ceph-deploy new $hostname --public-network 192.168.111.0/24 || exit 1
echo -e "\nosd pool default size = 1\nosd crush chooseleaf type = 0\n" >> "ceph.conf"

echo "Installing from upstream repository"
echo -e "\n[myrepo]\nbaseurl = http://gitbuilder.ceph.com/ceph-rpm-centos7-x86_64-basic/ref/master/x86_64\ngpgkey = https://download.ceph.com/keys/autobuild.asc\ndefault = True" >> .cephdeploy.conf
ceph-deploy install $hostname || exit 2

echo "Deploying Ceph monitor"
ceph-deploy mon create-initial || exit 3

echo "Deploying Ceph admin"
ceph-deploy admin $hostname

ceph-deploy disk zap $hostname:/dev/vdb

echo "Creating OSD on /dev/vdb"
ceph-deploy osd create $hostname:/dev/vdb || exit 3

echo "Creating default volumes pool"
ceph osd pool create volumes 100

echo "Deploying Ceph MDS"
ceph-deploy mds create $hostname || exit 4

echo "Health should be OK"
ceph -s

echo "Put Ceph to autostart"
systemctl enable ceph.target
systemctl enable ceph-mon.target
systemctl enable ceph-osd.target

echo "Installing ceph-mirror package and run it as a service"
yum install -y rbd-mirror || exit 5
systemctl enable ceph-rbd-mirror@admin
systemctl start ceph-rbd-mirror@admin
