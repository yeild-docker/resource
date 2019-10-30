#!/bin/sh

yum update -y
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
yum provides '*/applydeltarpm' && yum install deltarpm -y
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
yum install -y openssh-server vim wget gcc gcc-c++ automake autoconf libtool make zlib zlib-devel openssl openssl-devel lsof unzip zip bzip2 net-tools passwd cracklib-dicts intltool kde-l10n-Chinese pcre pcre-devel expect
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

# timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
echo -e "\nexport LC_ALL=en_US.UTF-8\nexport LANG=zh_CN.UTF-8\n" >> /etc/profile && source /etc/profile
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

# sshd
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

# mwget
wget http://jaist.dl.sourceforge.net/project/kmphpfm/mwget/0.1/mwget_0.1.0.orig.tar.bz2 && tar -xjvf mwget_0.1.0.orig.tar.bz2 && cd mwget_0.1.0.orig && ./configure && make && make install && cd .. && rm -rf mwget_0.1.0.orig*
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

#nginx
wget https://nginx.org/download/nginx-1.16.1.tar.gz && tar -zxvf nginx-1.16.1.tar.gz && cd nginx-1.16.1 && ./configure --prefix=/usr/local/nginx && make && make install && echo "export PATH=/usr/local/nginx/sbin:\$PATH" >> /etc/profile && source /etc/profile && cd .. && rm -rf nginx-1.16.1* && wget -P /lib/systemd/system https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/nginx/nginx.service && systemd enable nginx
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
systemctl start nginx

yum clean all && rm -rf /var/cache/yum/*

echo "Done"
exit 0
