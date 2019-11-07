#!/bin/bash
_PASSWORD="admin96515"
_PASSWORD_SSH="admin96515"
_FILE=""
_DATA="/data/gpdata"
_SEG_COUNTS=4
_MAP_HOST=/data/greenplum

while getopts ":hm:p:P:f:d:" opt
do
	case $opt in
		h)
		echo "Usage of Options:"
		echo "-h help"
		echo "-p password of Greenplum's user:gpadmin.Default:admin96515"
		echo "-P password of ssh within docker"
		echo "-f the rpm package file of Greenplum"
		echo "-d the Data Storage Areas path. Default: /data/gp"
			;;
		p)
		_PASSWORD=$OPTARG ;;
		P)
		_PASSWORD_SSH=$OPTARG ;;
		f)
		_FILE=$OPTARG ;;
		d)
		_DATA=$OPTARG ;;
		?)
		echo "Unsurported Option -${opt}"
		exit 1;;
	esac
done

mkdir -p ~/greenplum
cd ~/greenplum

if [[ ! "`grep '^199.232.4.133[[:blank:]]*raw.githubusercontent.com$' /etc/hosts`" ]]; then
	echo -e "\n199.232.4.133\traw.githubusercontent.com\n" >> /etc/hosts
fi

yum install -y wget sudo openssh expect

# run cluster with docker
docker &> /dev/null
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then
	echo "============================== Install docker =============================="
	curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/docker/init.sh" | sh -s -- -v 19.03.4
	cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 9 ]; then echo "Exit with Fail: ${cmd_rs}!"; exit $cmd_rs; fi
fi

mounts=" -v ${_MAP_HOST}/share:/data/share -v ${_MAP_HOST}/master:${_DATA}/master"
for serial in $(seq 1 $_SEG_COUNTS)
do
	mounts="${mounts} -v ${_MAP_HOST}/sdw${serial}/primary:${_DATA}/sdw${serial}/primary"
	mounts="${mounts} -v ${_MAP_HOST}/sdw${serial}/mirror:${_DATA}/sdw${serial}/mirror"
done
echo "============================== Docker Disk MapList =============================="
echo $mounts | sed "s|[[:blank:]]*-v[[:blank:]]*|\\n|g" | sed "s|:|    ====>    |g"
echo "================================================================================="

echo "============================== Init docker =============================="
echo "-------------------------> Create docker containner: gpmaster"
docker rm -f gpmaster &> /dev/null
docker run -tid --privileged=true --restart=always ${mounts} --add-host gpmaster:127.0.0.1 -p 5438:5432 --name gpmaster centos:7 /usr/sbin/init
cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 1 ]; then echo "Create docker containner gpmaster failed"; exit $cmd_rs; fi

_GPVERSION=6.0.1
_GPPACK=greenplum-db-${_GPVERSION}.rpm
_GPPWD=admin96515
_VM_SSHPWD=96515.cc
wget -c https://github.com/greenplum-db/gpdb/releases/download/${_GPVERSION}/greenplum-db-${_GPVERSION}-rhel7-x86_64.rpm -O ${_GPPACK}
cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 9 ]; then echo "Exit with Fail: ${cmd_rs}!"; exit $cmd_rs; fi
wget https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/db_Greenplum/single.sh -O single.sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 9 ]; then echo "Exit with Fail: ${cmd_rs}!"; exit $cmd_rs; fi
echo "-------------------------> Copy `pwd`/${_GPPACK} to /data/greenplum/share which shared to gpmaster"
mkdir -p ${_MAP_HOST}/share
expect<<!
spawn cp ./${_GPPACK} ${_MAP_HOST}/share/${_GPPACK}
expect {
	"overwrite" { send "y\r"; exp_continue; }
	eof
}
!
expect<<!
spawn cp ./single.sh ${_MAP_HOST}/share/single.sh
expect {
	"overwrite" { send "y\r"; exp_continue; }
	eof
}
!
_FILE=/data/share/${_GPPACK}

docker exec gpmaster /bin/sh -c "/bin/sh /data/share/single.sh -p ${_GPPWD} -d ${_DATA} -f ${_FILE}"
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail: ${cmd_rs}!"; exit $cmd_rs; fi

echo "============================== Deploy Done =============================="
exit 0
