#!/bin/bash
_PASSWORD=""

while getopts ":hp:" opt
do
	case $opt in
		h)
		echo "Usage of Options:"
		echo "-h help"
		echo "-p password of root user."
			;;
		p)
		_PASSWORD=$OPTARG ;;
		?)
		echo "Unsurported Option -${opt}"
		exit 1 ;;
	esac
done

yum install -y openssh-server passwd cracklib-dicts expect
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

if [ "$_PASSWORD" -ne "" ]; then
	echo root:$_PASSWORD | chpasswd
fi
sed -i 's/^[# \t]*\(Port 22\)$/\1/g' /etc/ssh/sshd_config
sed -i 's/^[# \t]*\(PermitRootLogin\).*$/PermitRootLogin yes/g' /etc/ssh/sshd_config

expect<<!
spawn ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
expect {
	"Overwrite" { send "y\r"; exp_continue; }
	"Enter file in which to save the key" { send "\r"; exp_continue; }
	"Enter passphrase" { send "\r"; exp_continue; }
	"Enter same passphrase agai" { send "\r"; exp_continue; }
}
expect eof
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
expect<<!
spawn ssh-keygen -t rsa -f /etc/ssh/ssh_host_ecdsa_key
expect {
	"Overwrite" { send "y\r"; exp_continue; }
	"Enter file in which to save the key" { send "\r"; exp_continue; }
	"Enter passphrase" { send "\r"; exp_continue; }
	"Enter same passphrase agai" { send "\r"; exp_continue; }
}
expect eof
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
expect<<!
spawn ssh-keygen -t rsa -f /etc/ssh/ssh_host_ed25519_key
expect {
	"Overwrite" { send "y\r"; exp_continue; }
	"Enter file in which to save the key" { send "\r"; exp_continue; }
	"Enter passphrase" { send "\r"; exp_continue; }
	"Enter same passphrase agai" { send "\r"; exp_continue; }
}
expect eof
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

systemctl enable sshd
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
systemctl start sshd

exit 0
