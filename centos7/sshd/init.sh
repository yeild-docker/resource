#!/bin/bash
_USER=""
_PASSWORD=""

while getopts ":hu:p:" opt
do
	case $opt in
		h)
		echo "Usage of Options:"
		echo "-h help"
		echo "-u user."
		echo "-p password of user."
			;;
		p)
		_PASSWORD=$OPTARG ;;
		u)
		_USER=$OPTARG ;;
		?)
		echo "Unsurported Option -${opt}"
		exit 1 ;;
	esac
done

workhome=`cd $(dirname $0); pwd -P`
cd $workhome

yum install -y openssh-server openssh-clients passwd cracklib-dicts expect
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

if [[ "$_PASSWORD" -ne "" ]]; then
	echo root:$_PASSWORD | chpasswd
fi
sed -i 's/^[# \t]*\(Port 22\)$/\1/g' /etc/ssh/sshd_config
sed -i 's/^[# \t]*\(PermitRootLogin\).*$/PermitRootLogin yes/g' /etc/ssh/sshd_config

expect<<!
spawn ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
expect {
	"Overwrite" { send "n\r"; exp_continue; }
	"Enter passphrase" { send "\r"; exp_continue; }
	"Enter same passphrase agai" { send "\r"; exp_continue; }
	eof
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
expect<<!
spawn ssh-keygen -t rsa -f /etc/ssh/ssh_host_ecdsa_key
expect {
	"Overwrite" { send "n\r"; exp_continue; }
	"Enter passphrase" { send "\r"; exp_continue; }
	"Enter same passphrase agai" { send "\r"; exp_continue; }
	eof
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
expect<<!
spawn ssh-keygen -t rsa -f /etc/ssh/ssh_host_ed25519_key
expect {
	"Overwrite" { send "n\r"; exp_continue; }
	"Enter passphrase" { send "\r"; exp_continue; }
	"Enter same passphrase agai" { send "\r"; exp_continue; }
	eof
}
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

systemctl enable sshd
systemctl start sshd
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then /usr/sbin/sshd; fi

exit 0
