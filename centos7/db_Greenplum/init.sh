#!/bin/bash
_MASTER=0
_PASSWORD="admin96515"
_FILE=""

while getopts ":hmp:f:" opt
do
	case $opt in
		h)
		echo "Usage of Options:"
		echo "-h help"
		echo "-m install with master"
		echo "-p password of Greenplum's user:gpadmin.Default:admin96515"
		echo "-f the rpm package file of Greenplum"
			;;
		m)
		_MASTER=1 ;;
		p)
		_PASSWORD=$OPTARG ;;
		f)
		_FILE=$OPTARG ;;
		?)
		echo "Unsurported Option -${opt}"
		exit 1;;
	esac
done

# echo -e "\n199.232.4.133\traw.githubusercontent.com\n" >> /etc/hosts
# sshd
# curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/sshd/init.sh" | sh -s -- -p eshxcmhk
# cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

yum install -y wget sudo openssh expect

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
fi

echo "Source envir of user gpadmin"
su - gpadmin << EOF
sudo chown -R gpadmin:gpadmin /usr/local/greenplum*
if [[ ! "`grep '^source /usr/local/greenplum-db/greenplum_path.sh$' /home/gpadmin/.bashrc`" ]]; then
	echo -e "\nsource /usr/local/greenplum-db/greenplum_path.sh\n" >> ~/.bashrc
fi
source ~/.bashrc
exit 0
EOF

if [ $_MASTER -eq 1 ]; then
echo "Generate ssh-keygen of user: gpadmin"
su - gpadmin << SUEOF
if [ ! -f ~/.ssh/id_rsa ]; then
expect<<!
spawn ssh-keygen -t rsa -b 4096
expect {
	"Overwrite" { send "n\r"; exp_continue; }
	"Enter file in which to save the key" { send "\r"; exp_continue; }
	"Enter passphrase" { send "\r"; exp_continue; }
	"Enter same passphrase agai" { send "\r"; exp_continue; }
}
expect eof
!
# cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
# fi
# expect<<!
# spawn ssh-copy-id -f gpsdw1
# expect {
# 	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
# 	"password:" { send "${_PASSWORD}\r"; exp_continue; }
# }
# expect eof
# !
# cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
# expect<<!
# spawn ssh-copy-id -f gpsdw2
# expect {
# 	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
# 	"password:" { send "${_PASSWORD}\r"; exp_continue; }
# }
# expect eof
# !
# cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
# expect<<!
# spawn ssh-copy-id -f gpsdw3
# expect {
# 	"Are you sure you want to continue connecting" { send "yes\r"; exp_continue; }
# 	"password:" { send "${_PASSWORD}\r"; exp_continue; }
# }
# expect eof
# !
# cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi


touch hostfile_exkeys
# echo -e "gpmaster" >> hostfile_exkeys
echo -e "gpsdw1" >> hostfile_exkeys
echo -e "gpsdw2" >> hostfile_exkeys
echo -e "gpsdw3" >> hostfile_exkeys
gpssh-exkeys -f hostfile_exkeys

exit 0
SUEOF
fi

echo "=========================================="
echo "Init Install Done!"
echo "password of gpadmin: ${_PASSWORD}"

exit 0
