#!/usr/bin/env bash

ROOTFS=/tmp/owncloud/rootfs
APP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
cd ${APP_DIR}
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

ARCH=$(dpkg-architecture -q DEB_HOST_GNU_CPU)

ROOTFS_FILE=3rdparty/rootfs-${ARCH}.tar.gz

if [ ! -f ${ROOTFS_FILE} ]; then
  if [ ! -d 3rdparty ]; then
    mkdir 3rdparty
  fi
  wget http://build.syncloud.org:8111/guestAuth/repository/download/debian_rootfs_syncloud_${ARCH}/lastSuccessful/rootfs.tar.gz\
  -O ${ROOTFS_FILE} --progress dot:giga
else
  echo "skipping rootfs: ${ROOTFS_FILE}"
fi

apt-get install docker.io
service docker start

function cleanup {

    mount | grep ${ROOTFS} | awk '{print "umounting "$1; system("umount "$3)}'

    echo "cleaning old rootfs"
    rm -rf ${ROOTFS}

    echo "docker images"
    docker images -q

    echo "removing images"
    docker rm $(docker kill $(docker ps -qa))
    docker rmi $(docker images -q)

    echo "docker images"
    docker images -q
}

cleanup

echo "extracting rootfs"
rm -rf ${ROOTFS}
mkdir -p ${ROOTFS}
tar xzf ${APP_DIR}/${ROOTFS_FILE} -C ${ROOTFS}
sed -i 's/Port 22/Port 2222/g' ${ROOTFS}/etc/ssh/sshd_config

echo "importing rootfs"
tar -C ${ROOTFS} -c . | docker import - syncloud

echo "starting rootfs"
docker run --net host -v /var/run/dbus:/var/run/dbus --name rootfs --privileged -d -it syncloud /sbin/init

ssh-keygen -f "/root/.ssh/known_hosts" -R [localhost]:2222

sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p 2222 root@localhost date
while test $? -gt 0
do
  sleep 1
  echo "Waiting for SSH ..."
  sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p 2222 root@localhost date
done

ssh-keygen -f "/root/.ssh/known_hosts" -R [localhost]:2222