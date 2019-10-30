
yum install -y openssh-server wget gcc gcc-c++ automake autoconf libtool make zlib zlib-devel openssl openssl-devel passwd cracklib-dicts expect
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

echo root:eshxcmhk | chpasswd
sed -i 's/^[# \t]*\(Port 22\)$/\1/g' /etc/ssh/sshd_config
sed -i 's/^[# \t]*\(PermitRootLogin\).*$/PermitRootLogin yes/g' /etc/ssh/sshd_config

expect<<!
spawn ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
expect "Enter passphrase" { send "\r" }
expect "Enter same passphrase again" { send "\r" }
expect eof
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
expect<<!
spawn ssh-keygen -t rsa -f /etc/ssh/ssh_host_ecdsa_key
expect "Enter passphrase" { send "\r" }
expect "Enter same passphrase again" { send "\r" }
expect eof
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
expect<<!
spawn ssh-keygen -t rsa -f /etc/ssh/ssh_host_ed25519_key
expect "Enter passphrase" { send "\r" }
expect "Enter same passphrase again" { send "\r" }
expect eof
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

systemctl enable sshd
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
systemctl start sshd

exit 0
