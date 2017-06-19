#!/bin/bash

lvm_install(){
    yum install -y yum-utils device-mapper-persistent-data lvm2
}
lvm_thin(){
    pvcreate $1
    vgcreate docker $1

    lvcreate --wipesignatures y -n thinpool docker -l 95%VG
    lvcreate --wipesignatures y -n thinpoolmeta docker -l 1%VG

    # convert our new logical volumes to a thinpool
    lvconvert -y --zero n -c 512K --thinpool docker/thinpool --poolmetadata docker/thinpoolmeta

    # setup docker thinpool profile
    cat <<-EOF > /etc/lvm/profile/docker-thinpool.profile
	activation {
	  thin_pool_autoextend_threshold=80
	  thin_pool_autoextend_percent=20
	}
	EOF
    lvchange --metadataprofile docker-thinpool docker/thinpool
}
docker_install(){
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum makecache fast
    yum -y install docker-ce.x86_64
    mkdir -p /etc/docker
    cat <<-EOF > /etc/docker/daemon.json
	{
	    "storage-driver": "devicemapper",
	    "storage-opts": [
	    "dm.thinpooldev=/dev/mapper/docker-thinpool",
	    "dm.use_deferred_removal=true",
	    "dm.use_deferred_deletion=true"
	    ]
	}
	EOF

    systemctl enable docker
    systemctl start docker
}



lvm_install
lvm_thin /dev/sdb

docker_install

# trust private registry endpoints
[ ! -z "$REGISTRY_ENDPOINT" ] && \
    mkdir -p /etc/docker/certs.d/$REGISTRY_ENDPOINT && \
    openssl s_client -connect $REGISTRY_ENDPOINT 2>/dev/null <<<""|sed -n '/-----BEGIN/,/-----END/p' > /etc/docker/certs.d/$REGISTRY_ENDPOINT/ca.crt && \
    cn=$(openssl x509 -noout -subject -in /etc/docker/certs.d/$REGISTRY_ENDPOINT/ca.crt |sed 's/.*CN=//') && \
    cp /etc/docker/certs.d/$REGISTRY_ENDPOINT/ca.crt /etc/pki/ca-trust/source/anchors/$cn.crt && \
    update-ca-trust
