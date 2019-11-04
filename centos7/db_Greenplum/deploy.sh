#!/bin/sh
echo "Work into ~/greenplum"
mkdir -p ~/greenplum
cd ~/greenplum

yum install -y wget

if [[ ! "`grep '^199.232.4.133\traw.githubusercontent.com$' /etc/hosts`" ]]; then
	echo -e "\n199.232.4.133\traw.githubusercontent.com\n" >> /etc/hosts
fi

# run cluster with docker
docker
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then
	curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/docker/init.sh" | sh -s -- -v 19.03.4
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
docker network create gpcluster
cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 1 ]; then echo "Create cluster network failed"; exit $cmd_rs; fi
docker run -tid --privileged=true --restart=always --network=gpcluster -p 5432:5432 --name gpmaster centos:7 /usr/sbin/init
docker run -tid --privileged=true --restart=always --network=gpcluster --name gpsdw1 centos:7 /usr/sbin/init
docker run -tid --privileged=true --restart=always --network=gpcluster --name gpsdw2 centos:7 /usr/sbin/init
docker run -tid --privileged=true --restart=always --network=gpcluster --name gpsdw3 centos:7 /usr/sbin/init

_GPVERSION=6.0.1
_GPPACK=greenplum-db-${_GPVERSION}.rpm
_GPPWD=admin96515
_VM_SSHPWD=96515.cc
wget -c https://github.com/greenplum-db/gpdb/releases/download/${_GPVERSION}/greenplum-db-${_GPVERSION}-rhel7-x86_64.rpm -O ${_GPPACK}
wget https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/db_Greenplum/init.sh -O init.sh
wget https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/db_Greenplum/master.sh -O master.sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
docker cp ./${_GPPACK} gpmaster:/${_GPPACK}
docker cp ./init.sh gpmaster:/init.sh
docker cp ./init.sh gpmaster:/master.sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
docker cp ./${_GPPACK} gpsdw1:/${_GPPACK}
docker cp ./init.sh gpsdw1:/init.sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
docker cp ./${_GPPACK} gpsdw2:/${_GPPACK}
docker cp ./init.sh gpsdw2:/init.sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
docker cp ./${_GPPACK} gpsdw3:/${_GPPACK}
docker cp ./init.sh gpsdw3:/init.sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi


echo "------------------Init gpsdw1------------------"
docker exec gpsdw1 /bin/sh -c "/bin/sh /init.sh -P ${_VM_SSHPWD} -f ${_GPPACK}"
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Init gpsdw1 Failed!"; exit $cmd_rs; fi
echo "------------------Init gpsdw2------------------"
docker exec gpsdw2 /bin/sh -c "/bin/sh /init.sh -P ${_VM_SSHPWD} -f ${_GPPACK}"
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Init gpsdw2 Failed!"; exit $cmd_rs; fi
echo "------------------Init gpsdw3------------------"
docker exec gpsdw3 /bin/sh -c "/bin/sh /init.sh -P ${_VM_SSHPWD} -f ${_GPPACK}"
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Init gpsdw3 Failed!"; exit $cmd_rs; fi
echo "------------------Init gpmaster------------------"
docker exec gpmaster /bin/sh -c "/bin/sh /init.sh -P ${_VM_SSHPWD} -p ${_GPPWD} -f ${_GPPACK}"
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Init gpmaster Failed!"; exit $cmd_rs; fi
docker exec gpmaster /bin/sh -c "/bin/sh /master.sh -p ${_GPPWD} -d /data/gp"
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Init gpmaster Failed!"; exit $cmd_rs; fi

exit 0
