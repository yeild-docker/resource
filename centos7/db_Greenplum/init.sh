#!/bin/bash
_MASTER=0
_PASSWORD="admin96515"
_FILE=""
_DATA="/data/gp"

while getopts ":hmp:f:d:" opt
do
	case $opt in
		h)
		echo "Usage of Options:"
		echo "-h help"
		echo "-m install with master"
		echo "-p password of Greenplum's user:gpadmin.Default:admin96515"
		echo "-f the rpm package file of Greenplum"
		echo "-d the Data Storage Areas path. Default: /data/gp"
			;;
		m)
		_MASTER=1 ;;
		p)
		_PASSWORD=$OPTARG ;;
		f)
		_FILE=$OPTARG ;;
		d)
		_DATA=$OPTARG ;;
		?)
		echo "Unsurported Option -${opt}"
		exit 1;;
	esac
done

echo -e "\n199.232.4.133\traw.githubusercontent.com\n" >> /etc/hosts
# sshd
curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/sshd/init.sh" | sh -s -- -p eshxcmhk
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

yum install -y wget sudo openssh expect

# sed -i "s|^\(SELINUX=\).*$|\1disabled|g" /etc/selinux/config
# systemctl stop firewalld && systemctl disable firewalld

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

echo "Source envir of user gpadmin"
su - gpadmin << EOF
if [[ ! "`grep '^source /usr/local/greenplum-db/greenplum_path.sh$' /home/gpadmin/.bashrc`" ]]; then
	echo -e "\nsource /usr/local/greenplum-db/greenplum_path.sh\n" >> ~/.bashrc
fi
source ~/.bashrc
exit 0
EOF

if [ $_MASTER == 1 ]; then
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
}
expect eof
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
}
expect eof
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
expect<<!
spawn ssh-copy-id -i /home/gpadmin/.ssh/id_rsa.pub gpadmin@gpsdw2
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	"password:" { send "${_PASSWORD}\r"; exp_continue; }
}
expect eof
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
expect<<!
spawn ssh-copy-id -i /home/gpadmin/.ssh/id_rsa.pub gpadmin@gpsdw3
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	"password:" { send "${_PASSWORD}\r"; exp_continue; }
}
expect eof
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
}
expect eof
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
# gpcheckperf -f hostfile_gpssh_segonly -r ds -D -d ${_DATA}/primary -d ${_DATA}/mirror
# cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Test Failed!"; exit $cmd_rs; fi

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
}
expect eof
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Rollback Failed!"; exit $cmd_rs; fi
rm -rf ~/gpAdminLogs/backout_gpinitsystem_*
fi

echo "Run gpinitsystem"
expect<<!
spawn gpinitsystem -c gpinitsystem_config -h hostfile_gpinitsystem
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	">" { send "y\r"; exp_continue; }
}
expect eof
!
# "Continue with Greenplum creation:" { sleep 1 send "y\r"; exp_continue; }
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "gpinitsystem exit:$cmd_rs";exit $cmd_rs; fi

exit 0
SUEOF
fi
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

echo "=========================================="
echo "Init Install Done!"
echo "password of gpadmin: ${_PASSWORD}"

exit 0
