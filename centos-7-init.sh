#!/usr/bin/expect
#!/bin/sh
#!/bin/bash

yum update -y
yum install -y openssh-server vim wget gcc gcc-c++ automake autoconf libtool make zlib zlib-devel openssl openssl-devel lsof unzip zip bzip2 net-tools passwd cracklib-dicts intltool kde-l10n-Chinese pcre pcre-devel expect

# sshd
echo root:eshxcmhk | chpasswd
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
expect<<!
spawn ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
expect "Enter passphrase" { send "\r" }
expect "Enter same passphrase again" { send "\r" }
expect eof
!
expect<<!
spawn ssh-keygen -t rsa -f /etc/ssh/ssh_host_ecdsa_key
expect "Enter passphrase" { send "\r" }
expect "Enter same passphrase again" { send "\r" }
expect eof
!
expect<<!
spawn ssh-keygen -t rsa -f /etc/ssh/ssh_host_ed25519_key
expect "Enter passphrase" { send "\r" }
expect "Enter same passphrase again" { send "\r" }
expect eof
!

systemctl enable sshd && systemctl start sshd

# timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

#nginx
mwget https://nginx.org/download/nginx-1.16.1.tar.gz && tar -zxvf nginx-1.16.1.tar.gz && cd nginx-1.16.1 && ./configure --prefix=/usr/local/nginx && make && make install && echo "export PATH=/usr/local/nginx/sbin:$PATH" >> /etc/profile && source /etc/profile



