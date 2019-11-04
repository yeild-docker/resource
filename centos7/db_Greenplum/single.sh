#!/bin/bash
_PASSWORD="admin96515"
_PASSWORD_SSH="admin96515"
_FILE=""
_DATA="/data/gp"
_SEG_COUNTS=4

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

if [[ ! "`grep '^199.232.4.133\traw.githubusercontent.com$' /etc/hosts`" ]]; then
	echo -e "\n199.232.4.133\traw.githubusercontent.com\n" >> /etc/hosts
fi

yum install -y wget sudo openssh expect

# run cluster with docker
docker &> /dev/null
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then
	curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/docker/init.sh" | sh -s -- -v 19.03.4
	cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 9 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
fi
# Add When production: -v /data:/data
docker run -tid --privileged=true --restart=always -p 5438:5432 --name gpmaster centos:7 /usr/sbin/init
cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 1 ]; then echo "Create docker containner gpmaster failed"; exit $cmd_rs; fi

_GPVERSION=6.0.1
_GPPACK=greenplum-db-${_GPVERSION}.rpm
_GPPWD=admin96515
_VM_SSHPWD=96515.cc
wget -c https://github.com/greenplum-db/gpdb/releases/download/${_GPVERSION}/greenplum-db-${_GPVERSION}-rhel7-x86_64.rpm -O ${_GPPACK}
cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 9 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
docker cp ./${_GPPACK} gpmaster:/${_GPPACK}

docker exec -ti gpmaster /bin/bash

# locale
echo "============================== Init locale =============================="
curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/locale/init.sh" | sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
# sshd
echo "============================== Init sshd =============================="
curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/sshd/init.sh" | sh -s -- -p $_PASSWORD_SSH
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi

echo "============================== Init Greenplum Install Evnironment =============================="
echo "-------------------------> Disable selinux"
sed -i "s|^\(SELINUX=\).*$|\1disabled|g" /etc/selinux/config

echo "-------------------------> Create Greenplum group: gpadmin"
groupadd -g 5999 gpadmin
cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 9 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
echo "-------------------------> Create Greenplum user: gpadmin"
useradd -u 5998 gpadmin -r -m -g gpadmin
cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 9 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi

echo "-------------------------> Passwd Greenplum user: gpadmin"
passwd gpadmin << EOF
$_PASSWORD
$_PASSWORD
EOF
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
echo "-------------------------> Grant sudo with Greenplum user: gpadmin"
sed -i 's/^#[ \t]*\(%wheel[ \t]*ALL=(ALL)[ \t]*NOPASSWD:[ \t]*ALL\)$/\1/g' /etc/sudoers
usermod -aG wheel gpadmin

echo "============================== Install Greenplum =============================="
if [ ! -d "/usr/local/greenplum-db" ]; then
	if [[ $_FILE = ""  ]] || [ ! -f $_FILE ]; then
		echo "-------------------------> Download Greenplum: https://github.com/greenplum-db/gpdb/releases/download/6.0.1/greenplum-db-6.0.1-rhel7-x86_64.rpm"
		wget https://github.com/greenplum-db/gpdb/releases/download/6.0.1/greenplum-db-6.0.1-rhel7-x86_64.rpm -O greenplum-db-6.0.1.rpm
		_FILE="`pwd`/greenplum-db-6.0.1.rpm"
		echo "-------------------------> Download Greenplum Complete:${_FILE}"
	fi
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
	echo "-------------------------> Install Greenplum with:${_FILE}"
	sudo yum install -y $_FILE
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
	echo "-------------------------> Install Complete to:/usr/local/greenplum-db"
	echo "-------------------------> chown -R gpadmin:gpadmin /usr/local/greenplum*"
	chown -R gpadmin:gpadmin /usr/local/greenplum*
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
fi

echo "============================== Prepare Greenplum Evnironment =============================="
echo "-------------------------> Configure default system config with:/etc/security/limits.d/20-nproc.conf"
if [[ ! -f "/etc/security/limits.d/20-nproc.conf.source" ]]; then
	echo "-------------------------> Backup source to:/etc/security/limits.d/20-nproc.conf.source"
	cp /etc/security/limits.d/20-nproc.conf /etc/security/limits.d/20-nproc.conf.source
fi
if [[ ! "`grep '^\(\*[[:blank:]]*soft[[:blank:]]*nproc[[:blank:]]*\)[0-9]*$' /etc/security/limits.d/20-nproc.conf`" ]]; then
	echo "* soft nproc 131072" >> /etc/security/limits.d/20-nproc.conf
else
	sed -i 's|^\(\*[[:blank:]]*soft[[:blank:]]*nproc[[:blank:]]*\) [0-9]*$|\1 131072|g' /etc/security/limits.d/20-nproc.conf
fi
if [[ ! "`grep '^\(\*[[:blank:]]*soft[[:blank:]]*nofile[[:blank:]]*\)[0-9]*$' /etc/security/limits.d/20-nproc.conf`" ]]; then
	echo "* soft nofile 524288" >> /etc/security/limits.d/20-nproc.conf
else
	sed -i 's|^\(\*[[:blank:]]*soft[[:blank:]]*nofile[[:blank:]]*\) [0-9]*$|\1 524288|g' /etc/security/limits.d/20-nproc.conf
fi
if [[ ! "`grep '^\(\*[[:blank:]]*hard[[:blank:]]*nproc[[:blank:]]*\)[0-9]*$' /etc/security/limits.d/20-nproc.conf`" ]]; then
	echo "* hard nproc 131072" >> /etc/security/limits.d/20-nproc.conf
else
	sed -i 's|^\(\*[[:blank:]]*hard[[:blank:]]*nproc[[:blank:]]*\) [0-9]*$|\1 131072|g' /etc/security/limits.d/20-nproc.conf
fi
if [[ ! "`grep '^\(\*[[:blank:]]*hard[[:blank:]]*nofile[[:blank:]]*\)[0-9]*$' /etc/security/limits.d/20-nproc.conf`" ]]; then
	echo "* hard nofile 524288" >> /etc/security/limits.d/20-nproc.conf
else
	sed -i 's|^\(\*[[:blank:]]*hard[[:blank:]]*nofile[[:blank:]]*\) [0-9]*$|\1 524288|g' /etc/security/limits.d/20-nproc.conf
fi
if [[ ! "`grep '^-1000$' /proc/self/oom_score_adj`" ]]; then
	echo -1000 > /proc/self/oom_score_adj
fi

if [[ ! "`grep '^kernel.shmall[[:blank:]]*=.*$' /etc/sysctl.conf`" ]]; then
echo "-------------------------> Configure default system config with:/etc/sysctl.conf"
PAGE_SIZE=`getconf PAGESIZE || getconf PAGE_SIZE`
cat >> /etc/sysctl.conf << EOF
# Add by Greenplum
# 共享内存段的最大尺寸 kernel.shmall = _PHYS_PAGES / 2
kernel.shmall = $[`getconf _PHYS_PAGES` / 2]
# 系统任意时刻可以分配的所有共享内存段的总和的最大值 kernel.shmmax = kernel.shmall * PAGE_SIZE
kernel.shmmax = $[`getconf _PHYS_PAGES` / 2 * $PAGE_SIZE]
# 系统范围内共享内存段的最大数量
kernel.shmmni = 4096
vm.overcommit_memory = 2
vm.overcommit_ratio = 95
net.ipv4.ip_local_port_range = 10000 65535
kernel.sem = 500 2048000 200 40960
kernel.sysrq = 1
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.msgmni = 2048
# net.ipv4.tcp_syncookies = 1
net.ipv4.conf.default.accept_source_route = 0
# net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.conf.all.arp_filter = 1
# net.core.netdev_max_backlog = 10000
# net.core.rmem_max = 2097152
# net.core.wmem_max = 2097152
vm.swappiness = 10
vm.zone_reclaim_mode = 0
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
vm.dirty_background_ratio = 0
vm.dirty_ratio = 0
vm.dirty_background_bytes = 1610612736 # 1.5G
vm.dirty_bytes = 4294967296 # 4G

EOF
fi

sysctl -p

echo "-------------------------> Configure envir of user gpadmin"
su - gpadmin << EOF
echo "-------------------------> Work with user: `whoami`"
_home=`pwd`
if [[ ! "`grep '^source /usr/local/greenplum-db/greenplum_path.sh$' ${_home}/.bashrc`" ]]; then
	echo "-------------------------> Add 'source /usr/local/greenplum-db/greenplum_path.sh' to ${_home}/.bashrc"
	echo -e "\nsource /usr/local/greenplum-db/greenplum_path.sh\n" >> ${_home}/.bashrc
fi
if [[ ! "`grep '^export PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj$' ${_home}/.bashrc`" ]]; then
	echo "-------------------------> Add 'export PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj' to ${_home}/.bashrc"
	echo -e "export PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj\n" >> ${_home}/.bashrc
fi
if [[ ! "`grep '^export PG_OOM_ADJUST_VALUE=0$' ${_home}/.bashrc`" ]]; then
	echo "-------------------------> Add 'export PG_OOM_ADJUST_VALUE=0' to ${_home}/.bashrc"
	echo -e "export PG_OOM_ADJUST_VALUE=0\n" >> ${_home}/.bashrc
fi
if [[ ! "`grep '^export MASTER_DATA_DIRECTORY=.*$' ${_home}/.bashrc`" ]]; then
	echo "-------------------------> Add 'export MASTER_DATA_DIRECTORY=${_DATA}/master/gpseg-1' to ${_home}/.bashrc"
	echo -e "export MASTER_DATA_DIRECTORY=${_DATA}/master/gpseg-1\n" >> ${_home}/.bashrc
fi

source ~/.bashrc
exit 0
EOF

echo "============================== Init Greenplum Master =============================="
echo "============================== Generate ssh-keygen of user: gpadmin =============================="
su - gpadmin << SUEOF
echo "-------------------------> Work with user: `whoami`"
echo "-------------------------> Generate ssh-keygen of user: `whoami`"
source ~/.bashrc
rm -rf ~/.ssh/known_hosts
expect<<!
spawn ssh-keygen -t rsa -b 4096
expect {
	"Overwrite" { send "y\r"; exp_continue; }
	"Enter file in which to save the key" { send "\r"; exp_continue; }
	"Enter passphrase" { send "\r"; exp_continue; }
	"Enter same passphrase agai" { send "\r"; exp_continue; }
	eof
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
exit 0
SUEOF
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi

echo "============================== Enabling n-n Passwordless SSH of user: gpadmin =============================="
su - gpadmin << SUEOF
echo "-------------------------> Work with user: `whoami`"
echo "-------------------------> Create config of exchange: hostfile_exkeys"
if [ -f "hostfile_exkeys" ]; then
	rm -rf hostfile_exkeys
fi
touch hostfile_exkeys
echo -e "gpmaster" >> hostfile_exkeys
cat hostfile_exkeys
echo "-------------------------> Exchange ssh keys with:hostfile_exkeys"
expect<<!
spawn gpssh-exkeys -f hostfile_exkeys
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	"password:" { send "${_PASSWORD}\r"; exp_continue; }
	eof
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
exit 0
SUEOF
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi

echo "============================== Configure Greenplum cluster =============================="
_SEGMENTS=""
_MIRRORS=""
su - gpadmin << SUEOF
echo "-------------------------> Work with user: `whoami`"
if [ -f "hostfile" ]; then
	rm -rf hostfile
fi
touch hostfile
echo "gpmaster" >> hostfile

echo "-------------------------> Create Data Storage Areas for Master:${_DATA}/master"
sudo mkdir -p ${_DATA}/master
sudo chown gpadmin:gpadmin ${_DATA}/master

echo "-------------------------> To create 'hostfile_gpssh_segonly' which contains all segment hosts"
if [ -f "hostfile_gpssh_segonly" ]; then
	rm -rf hostfile_gpssh_segonly
fi
touch hostfile_gpssh_segonly
echo "gpmaster" >> hostfile_gpssh_segonly

cat hostfile_gpssh_segonly

echo "-------------------------> Create Data Storage Areas for Segment: ${_DATA}/sdw{serial}/primary ${_DATA}/mirror"
for serial in {1, $_SEG_COUNTS}
do
	primary=${_DATA}/sdw${serial}/primary
	mirror=${_DATA}/sdw${serial}/mirror
	_SEGMENTS=${_SEGMENTS}" "${primary}
	_MIRRORS=${_SEGMENTS}" "${mirror}
	sudo mkdir -p $primary
	sudo mkdir -p $mirror
	sudo chown -R gpadmin ${_DATA}/sdw${serial}/*
done

# echo "-------------------------> Create Data Storage Areas for standby master: ${_DATA}/master"
# gpssh -h smdw -e "mkdir -p ${_DATA}/master"
# cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
# gpssh -h smdw -e "chown gpadmin:gpadmin ${_DATA}/master"
# cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi

exit 0
SUEOF
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi

echo "============================== Prepare Init Greenplum Cluster =============================="
su - gpadmin << SUEOF
source ~/.bashrc
echo "-------------------------> Run test for segments"
gpcheckperf -f hostfile_gpssh_segonly -r ds -D -d ${_DATA}/primary -d ${_DATA}/mirror
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Test Failed!"; exit $cmd_rs; fi

echo "-------------------------> Config list of segment hosts which to init: 'hostfile_gpinitsystem'"
if [ -f "hostfile_gpinitsystem" ]; then
	rm -rf hostfile_gpinitsystem
fi
touch hostfile_gpinitsystem
echo "gpsdw1" >> hostfile_gpinitsystem
echo "gpsdw2" >> hostfile_gpinitsystem
echo "gpsdw3" >> hostfile_gpinitsystem

cat hostfile_gpinitsystem

sh /usr/local/greenplum-db/greenplum_path.sh
echo "-------------------------> Create Configure of Greenplum Cluster with file 'gpinitsystem_config'"
rm -rf ./gpinitsystem_config
cp /usr/local/greenplum-db/docs/cli_help/gpconfigs/gpinitsystem_config ./gpinitsystem_config
sed -i "s|^\(declare[[:blank:]]*-a[[:blank:]]*DATA_DIRECTORY=\).*$|\1(${_SEGMENTS})|g" ./gpinitsystem_config
sed -i "s|^\(MASTER_HOSTNAME=\).*$|\1gpmaster|g" ./gpinitsystem_config
sed -i "s|^\(MASTER_DIRECTORY=\).*$|\1${_DATA}/master|g" ./gpinitsystem_config

sed -i "s|^[#]*[[:blank:]]*\(MIRROR_PORT_BASE=.*\)$|\1|g" ./gpinitsystem_config
sed -i "s|^[#]*[[:blank:]]*\(declare[[:blank:]]*-a[[:blank:]]*MIRROR_DATA_DIRECTORY=\).*$|\1(${_SEGMENTS})|g" ./gpinitsystem_config

sed -i "s|^\(ENCODING=\).*$|\1UTF-8|g" ./gpinitsystem_config

# If the gpinitsystem utility fails, it will create the following backout script if it has left your system in a partially installed state:
# ~/gpAdminLogs/backout_gpinitsystem_<user>_<timestamp>
echo "-------------------------> Check of Last Init Fail '~/gpAdminLogs/backout_gpinitsystem_<user>_<timestamp>'"
ls ~/gpAdminLogs/backout_gpinitsystem_* &> /dev/null
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then
echo "-------------------------> Rollback Last Init Fail '~/gpAdminLogs/backout_gpinitsystem_<user>_<timestamp>'"
sed -i "1,1s/^/#/" ~/gpAdminLogs/backout_gpinitsystem_*
expect<<!
spawn sh ~/gpAdminLogs/backout_gpinitsystem_*
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	eof
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Rollback Failed!"; exit $cmd_rs; fi
rm -rf ~/gpAdminLogs/backout_gpinitsystem_*
else
echo "------------------------- WARN -------------------------"
echo "If gpinitsystem report data directory already exists, Run this to clean:"
echo "gpssh -f hostfile_gpssh_segonly -e 'sudo rm -rf ${_DATA}/primary/* && sudo rm -rf ${_DATA}/mirror/*'"
echo "sudo rm -rf ${_DATA}/master/*"
echo "--------------------------------------------------------"
fi
rm -rf ~/gpAdminLogs/gpinitsystem*

echo "------------------------- WARN -------------------------"
echo "If gpinitsystem report port has been used, Run this to clean:"
echo "rm -rf /tmp/*PGSQL.5432*"
echo "--------------------------------------------------------"

echo "============================== Start Init Greenplum Cluster =============================="
expect<<!
set timeout 3600
spawn gpinitsystem -a -c gpinitsystem_config -h hostfile_gpinitsystem --su-password=${_PASSWORD} -n zh_CN.UTF-8
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	">" { send "y\r"; exp_continue; }
	eof
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "gpinitsystem exit:$cmd_rs";exit $cmd_rs; fi

exit 0
SUEOF

cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi

if [[ ! "`ps aux|grep postgres.*master.*process | grep -v grep`" ]]; then
	echo "Init Greenplum Cluster Failed!"
	exit 1
fi

su - gpadmin << SUEOF
if [[ ! "`grep '^host[[:blank:]]*all[[:blank:]]*all[[:blank:]]*0.0.0.0/0[[:blank:]]*md5$' ${_DATA}/master/gpseg-1/pg_hba.conf`" ]]; then
	echo "-------------------------> Add 'host     all         all             0.0.0.0/0  md5' To ${_DATA}/master/gpseg-1/pg_hba.conf"
	echo "host     all         all             0.0.0.0/0  md5" >> ${_DATA}/master/gpseg-1/pg_hba.conf
fi

# psql -d postgres -c "ALTER USER gpadmin with PASSWORD '${_PASSWORD}';"
# gpstop -u

SUEOF

echo "============================== INFO =============================="
echo "=                       Init Install Done!                       ="
echo "=                Password of gpadmin: ${_PASSWORD}               ="
echo "=================================================================="

exit 0
