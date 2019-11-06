#!/bin/bash
_PASSWORD="admin96515"
_DATA="/data/gp"

while getopts ":hp:d:" opt
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
		p)
		_PASSWORD=$OPTARG ;;
		d)
		_DATA=$OPTARG ;;
		?)
		echo "Unsurported Option -${opt}"
		exit 1;;
	esac
done

echo "============================== Init Greenplum Master =============================="
echo "============================== Generate ssh-keygen of user: gpadmin =============================="
su - gpadmin << SUEOF
echo -e "-------------------------> Work with user: \c" && whoami
echo -e "-------------------------> Generate ssh-keygen of user: \c" && whoami
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

echo "============================== Enabling 1-n Passwordless SSH of user: gpadmin =============================="
su - gpadmin << SUEOF
echo -e "-------------------------> Work with user: \c" && whoami
echo "-------------------------> Copy ssh-keygen to gpsdw1"
expect<<!
spawn ssh-copy-id -i ~/.ssh/id_rsa.pub `whoami`@gpsdw1
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	"password:" { send "${_PASSWORD}\r"; exp_continue; }
	eof
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
echo "-------------------------> Copy ssh-keygen to gpsdw2"
expect<<!
spawn ssh-copy-id -i ~/.ssh/id_rsa.pub `whoami`@gpsdw2
expect {
	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
	"password:" { send "${_PASSWORD}\r"; exp_continue; }
	eof
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
echo "-------------------------> Copy ssh-keygen to gpsdw3"
expect<<!
spawn ssh-copy-id -i ~/.ssh/id_rsa.pub `whoami`@gpsdw3
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

echo "============================== Enabling n-n Passwordless SSH of user: gpadmin =============================="
su - gpadmin << SUEOF
echo -e "-------------------------> Work with user: \c" && whoami
echo "-------------------------> Create config of exchange: hostfile_exkeys"
if [ -f "hostfile_exkeys" ]; then
	rm -rf hostfile_exkeys
fi
touch hostfile_exkeys
# echo -e "gpmaster" >> hostfile_exkeys
echo -e "gpsdw1" >> hostfile_exkeys
echo -e "gpsdw2" >> hostfile_exkeys
echo -e "gpsdw3" >> hostfile_exkeys
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
su - gpadmin << SUEOF
echo -e "-------------------------> Work with user: \c" && whoami
if [ -f "hostfile" ]; then
	rm -rf hostfile
fi
touch hostfile
echo "gpmaster" >> hostfile
echo "gpsdw1" >> hostfile
echo "gpsdw2" >> hostfile
echo "gpsdw3" >> hostfile

echo "-------------------------> Create Data Storage Areas for Master:${_DATA}/master"
sudo mkdir -p ${_DATA}/master
sudo chown gpadmin:gpadmin ${_DATA}/master

echo "-------------------------> To create 'hostfile_gpssh_segonly' which contains all segment hosts"
if [ -f "hostfile_gpssh_segonly" ]; then
	rm -rf hostfile_gpssh_segonly
fi
touch hostfile_gpssh_segonly
echo "gpsdw1" >> hostfile_gpssh_segonly
echo "gpsdw2" >> hostfile_gpssh_segonly
echo "gpsdw3" >> hostfile_gpssh_segonly

cat hostfile_gpssh_segonly

echo "-------------------------> Create Data Storage Areas for Segment which in 'hostfile_gpssh_segonly': ${_DATA}/primary ${_DATA}/mirror"
gpssh -f hostfile_gpssh_segonly -e "sudo mkdir -p ${_DATA}/primary"
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
gpssh -f hostfile_gpssh_segonly -e "sudo mkdir -p ${_DATA}/mirror"
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
gpssh -f hostfile_gpssh_segonly -e "sudo chown -R gpadmin ${_DATA}/*"
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi

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
echo -e "-------------------------> Work with user: \c" && whoami
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
sed -i "s|^\(declare[[:blank:]]*-a[[:blank:]]*DATA_DIRECTORY=\).*$|\1(${_DATA}/primary ${_DATA}/primary)|g" ./gpinitsystem_config
sed -i "s|^\(MASTER_HOSTNAME=\).*$|\1gpmaster|g" ./gpinitsystem_config
sed -i "s|^\(MASTER_DIRECTORY=\).*$|\1${_DATA}/master|g" ./gpinitsystem_config

sed -i "s|^[#]*[[:blank:]]*\(MIRROR_PORT_BASE=.*\)$|\1|g" ./gpinitsystem_config
sed -i "s|^[#]*[[:blank:]]*\(declare[[:blank:]]*-a[[:blank:]]*MIRROR_DATA_DIRECTORY=\).*$|\1(${_DATA}/mirror ${_DATA}/mirror)|g" ./gpinitsystem_config

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

exit 0
