#!/bin/bash
_PASSWORD="admin96515"
_PASSWORD_SSH="admin96515"
_FILE=""
_DATA="/data/gp"

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

if [[ ! "`grep '^199.232.4.133[[:blank:]]*raw.githubusercontent.com$' /etc/hosts`" ]]; then
	echo -e "\n199.232.4.133\traw.githubusercontent.com\n" >> /etc/hosts
fi

# locale
echo "============================== Init locale =============================="
curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/locale/init.sh" | sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
echo "============================== Init locale Done =============================="
# sshd
echo "============================== Init sshd =============================="
curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/sshd/init.sh" | sh -s -- -p $_PASSWORD_SSH
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
echo "============================== Init sshd Done =============================="

echo "============================== Init Greenplum Install Evnironment =============================="
yum install -y wget sudo openssh expect

echo "-------------------------> Disable selinux"
sed -i "s|^\(SELINUX=\).*$|\1disabled|g" /etc/selinux/config

echo "-------------------------> Create Greenplum group: gpadmin"
groupadd -g 5999 gpadmin
cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 9 ]; then echo 'error'; exit $cmd_rs; fi
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

echo "============================== INFO =============================="
echo "=                       Init Install Done!                       ="
echo "=                Password of gpadmin: ${_PASSWORD}               ="
echo "=================================================================="

exit 0
