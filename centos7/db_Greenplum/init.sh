#!/bin/bash
_MASTER=0
_PASSWORD="admin96515"
_PASSWORD_SSH="admin96515"
_FILE=""
_DATA="/data/gp"

while getopts ":hmp:P:f:d:" opt
do
	case $opt in
		h)
		echo "Usage of Options:"
		echo "-h help"
		echo "-m install with master"
		echo "-p password of Greenplum's user:gpadmin.Default:admin96515"
		echo "-P password of ssh within docker"
		echo "-f the rpm package file of Greenplum"
		echo "-d the Data Storage Areas path. Default: /data/gp"
			;;
		m)
		_MASTER=1 ;;
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

if [[ ! "`grep '^199.232.4.133\traw.githubusercontent.com$' /etc/hosts`" ]]; then
	echo -e "\n199.232.4.133\traw.githubusercontent.com\n" >> /etc/hosts
fi
# sshd
curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/sshd/init.sh" | sh -s -- -p $_PASSWORD_SSH
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

yum install -y wget sudo openssh expect

sed -i "s|^\(SELINUX=\).*$|\1disabled|g" /etc/selinux/config

echo "Create group: gpadmin"
groupadd -g 5999 gpadmin
cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 9 ]; then echo 'error'; exit $cmd_rs; fi
echo "Create user: gpadmin"
useradd -u 5998 gpadmin -r -m -g gpadmin
cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 9 ]; then exit $cmd_rs; fi

echo "Passwd user: gpadmin"
passwd gpadmin << EOF
$_PASSWORD
$_PASSWORD
EOF
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
sed -i 's/^#[ \t]*\(%wheel[ \t]*ALL=(ALL)[ \t]*NOPASSWD:[ \t]*ALL\)$/\1/g' /etc/sudoers
usermod -aG wheel gpadmin

echo "Install Greenplum"
if [ ! -d "/usr/local/greenplum-db" ]; then
	if [[ $_FILE = ""  ]] || [ ! -f $_FILE ]; then
		wget https://github.com/greenplum-db/gpdb/releases/download/6.0.1/greenplum-db-6.0.1-rhel7-x86_64.rpm -O greenplum-db-6.0.1.rpm
		_FILE="`pwd`/greenplum-db-6.0.1.rpm"
	fi
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	sudo yum install -y $_FILE
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	echo "chown -R gpadmin:gpadmin /usr/local/greenplum*"
	chown -R gpadmin:gpadmin /usr/local/greenplum*
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi

if [[ ! "`grep '^kernel.shmall[[:blank:]]*=.*$' /etc/sysctl.conf`" ]]; then
cat >> /etc/sysctl.conf << EOF
# kernel.shmall = _PHYS_PAGES / 2 # See Note 1
kernel.shmall = 500000
# kernel.shmmax = kernel.shmall * PAGE_SIZE # See Note 1
kernel.shmmax = 1000000
kernel.shmmni = 4096
vm.overcommit_memory = 2
vm.overcommit_ratio = 95 # See Note 2
net.ipv4.ip_local_port_range = 10000 65535 # See Note 3
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
vm.dirty_background_ratio = 0 # See Note 5
vm.dirty_ratio = 0
vm.dirty_background_bytes = 1610612736
vm.dirty_bytes = 4294967296
EOF
fi
if [[ ! "`grep '^-1000$' /proc/self/oom_score_adj`" ]]; then
	echo -1000 > /proc/self/oom_score_adj
fi
sysctl -p

echo "Source envir of user gpadmin"
su - gpadmin << EOF
if [[ ! "`grep '^source /usr/local/greenplum-db/greenplum_path.sh$' /home/gpadmin/.bashrc`" ]]; then
	echo -e "\nsource /usr/local/greenplum-db/greenplum_path.sh\n" >> ~/.bashrc
fi
if [[ ! "`grep '^export PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj$' /home/gpadmin/.bashrc`" ]]; then
	echo -e "export PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj\n" >> ~/.bashrc
fi
if [[ ! "`grep '^export PG_OOM_ADJUST_VALUE=0$' /home/gpadmin/.bashrc`" ]]; then
	echo -e "export PG_OOM_ADJUST_VALUE=0\n" >> ~/.bashrc
fi
if [[ ! "`grep '^export MASTER_DATA_DIRECTORY=.*$' /home/gpadmin/.bashrc`" ]]; then
	echo -e "export MASTER_DATA_DIRECTORY=${_DATA}/master/gpseg-1\n" >> ~/.bashrc
fi

source ~/.bashrc
exit 0
EOF

if [[ $_MASTER = 1 ]]; then
echo "Generate ssh-keygen of user: gpadmin"
su - gpadmin << SUEOF
source /usr/local/greenplum-db/greenplum_path.sh
rm -rf ~/.ssh/known_hosts
# if [ ! -f ~/.ssh/id_rsa ]; then
expect<<!
spawn ssh-keygen -t rsa -b 4096
expect {
	"Overwrite" { send "y\r"; exp_continue; }
	"Enter file in which to save the key" { send "\r"; exp_continue; }
	"Enter passphrase" { send "\r"; exp_continue; }
	"Enter same passphrase agai" { send "\r"; exp_continue; }
	eof { send_user "eof" }
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
# fi
exit 0
SUEOF
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

su - gpadmin << SUEOF
echo "Work in `whoami`"
expect<<!
spawn ssh-copy-id -i /home/gpadmin/.ssh/id_rsa.pub gpadmin@gpsdw1
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	"password:" { send "${_PASSWORD}\r"; exp_continue; }
	eof { send_user "eof" }
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
expect<<!
spawn ssh-copy-id -i /home/gpadmin/.ssh/id_rsa.pub gpadmin@gpsdw2
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	"password:" { send "${_PASSWORD}\r"; exp_continue; }
	eof { send_user "eof" }
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
expect<<!
spawn ssh-copy-id -i /home/gpadmin/.ssh/id_rsa.pub gpadmin@gpsdw3
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	"password:" { send "${_PASSWORD}\r"; exp_continue; }
	eof { send_user "eof" }
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
exit 0
SUEOF
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

su - gpadmin << SUEOF
echo "Exchange ssh keys with:hostfile_exkeys"
if [ -f "hostfile_exkeys" ]; then
	rm -rf hostfile_exkeys
fi
touch hostfile_exkeys
# echo -e "gpmaster" >> hostfile_exkeys
echo -e "gpsdw1" >> hostfile_exkeys
echo -e "gpsdw2" >> hostfile_exkeys
echo -e "gpsdw3" >> hostfile_exkeys
expect<<!
spawn gpssh-exkeys -f hostfile_exkeys
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	"password:" { send "${_PASSWORD}\r"; exp_continue; }
	eof { send_user "eof" }
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
exit 0
SUEOF
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

su - gpadmin << SUEOF
if [ -f "hostfile" ]; then
	rm -rf hostfile
fi
touch hostfile
echo -e "gpmaster" >> hostfile
echo -e "gpsdw1" >> hostfile
echo -e "gpsdw2" >> hostfile
echo -e "gpsdw3" >> hostfile

echo "Create Data Storage Areas for Master:${_DATA}/master"
sudo mkdir -p ${_DATA}/master
sudo chown gpadmin:gpadmin ${_DATA}/master

echo "Create Data Storage Areas for Segment:"
echo "	${_DATA}/primary ${_DATA}/mirror"

if [ -f "hostfile_gpssh_segonly" ]; then
	rm -rf hostfile_gpssh_segonly
fi
touch hostfile_gpssh_segonly
echo -e "gpsdw1" >> hostfile_gpssh_segonly
echo -e "gpsdw2" >> hostfile_gpssh_segonly
echo -e "gpsdw3" >> hostfile_gpssh_segonly

gpssh -f hostfile_gpssh_segonly -e "sudo mkdir -p ${_DATA}/primary"
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
gpssh -f hostfile_gpssh_segonly -e "sudo mkdir -p ${_DATA}/mirror"
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
gpssh -f hostfile_gpssh_segonly -e "sudo chown -R gpadmin ${_DATA}/*"
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

# create the master data directory location on standby master
# gpssh -h smdw -e "mkdir -p ${_DATA}/master"
# gpssh -h smdw -e "chown gpadmin:gpadmin ${_DATA}/master"

gpssh -f hostfile_gpssh_segonly -e "sudo rm -rf ${_DATA}/primary/* && sudo rm -rf ${_DATA}/mirror/*" &> /dev/null
sudo rm -rf ${_DATA}/master/* &> /dev/null
exit 0
SUEOF
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

su - gpadmin << SUEOF
echo "Run test for segment"
gpcheckperf -f hostfile_gpssh_segonly -r ds -D -d ${_DATA}/primary -d ${_DATA}/mirror
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Test Failed!"; exit $cmd_rs; fi

echo "-----------Initializing Greenplum Database-----------"
echo "create hostfile_gpinitsystem"
if [ -f "hostfile_gpinitsystem" ]; then
	rm -rf hostfile_gpinitsystem
fi
touch hostfile_gpinitsystem
echo -e "gpsdw1" >> hostfile_gpinitsystem
echo -e "gpsdw2" >> hostfile_gpinitsystem
echo -e "gpsdw3" >> hostfile_gpinitsystem

sh /usr/local/greenplum-db/greenplum_path.sh
echo "Configure gpinitsystem_config"
rm -rf ./gpinitsystem_config
cp /usr/local/greenplum-db/docs/cli_help/gpconfigs/gpinitsystem_config ./gpinitsystem_config
sed -i "s|^\(declare[[:blank:]]*-a[[:blank:]]*DATA_DIRECTORY=\).*$|\1(/data/gp/primary /data/gp/primary /data/gp/primary)|g" ./gpinitsystem_config
sed -i "s|^\(MASTER_HOSTNAME=\).*$|\1gpmaster|g" ./gpinitsystem_config
sed -i "s|^\(MASTER_DIRECTORY=\).*$|\1${_DATA}/master|g" ./gpinitsystem_config

# If the gpinitsystem utility fails, it will create the following backout script if it has left your system in a partially installed state:
# ~/gpAdminLogs/backout_gpinitsystem_<user>_<timestamp>
echo "check last fails"
ls ~/gpAdminLogs/backout_gpinitsystem_* &> /dev/null
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then
echo "Rollback gpinitsystem utility fails"
sed -i "1,1s/^/#/" ~/gpAdminLogs/backout_gpinitsystem_*
expect<<!
spawn sh ~/gpAdminLogs/backout_gpinitsystem_*
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	eof { send_user "eof" }
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Rollback Failed!"; exit $cmd_rs; fi
rm -rf ~/gpAdminLogs/backout_gpinitsystem_*
fi
rm -rf ~/gpAdminLogs/gpinitsystem*

echo "Run gpinitsystem"
expect<<!
set timeout 3600
spawn gpinitsystem -c gpinitsystem_config -h hostfile_gpinitsystem
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	">" { send "y\r"; exp_continue; }
	eof { send_user "eof" }
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "gpinitsystem exit:$cmd_rs";exit $cmd_rs; fi
if [[ ! "`grep '^host[[:blank:]]*all[[:blank:]]*all[[:blank:]]*0.0.0.0/0[[:blank:]]*md5$' ${_DATA}/master/gpseg-1/pg_hba.conf`" ]]; then
	echo "host     all         all             0.0.0.0/0  md5" >> ${_DATA}/master/gpseg-1/pg_hba.conf
	gpstop -u
fi

exit 0
SUEOF
fi
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

echo "=========================================="
echo "Init Install Done!"
echo "password of gpadmin: ${_PASSWORD}"

exit 0
