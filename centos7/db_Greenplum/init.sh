
# run cluster with docker
curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/docker/init.sh" | sh -s -- -v 19.03.4
docker run -tid --privileged=true -p 5432:5432 --name gpmaster centos:7 /usr/sbin/init
docker run -tid --privileged=true --name gpsdw1 centos:7 /usr/sbin/init
docker run -tid --privileged=true --name gpsdw2 centos:7 /usr/sbin/init
docker run -tid --privileged=true --name gpsdw3 centos:7 /usr/sbin/init
docker exec -it gpmaster /bin/bash

yum install -y wget sudo openssh expect

groupadd -g 5999 gpadmin
cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 9 ]; then echo 'error'; exit $cmd_rs; fi
useradd -u 5998 gpadmin -r -m -g gpadmin
cmd_rs=$?; if [ $cmd_rs -ne 0 ] && [ $cmd_rs -ne 9 ]; then exit $cmd_rs; fi
passwd gpadmin << EOF
admin96515
admin96515
EOF
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

su - gpadmin << EOF
expect<<!
spawn ssh-keygen -t rsa -b 4096
expect "Overwrite" { send "y\r" }
expect "Enter file in which to save the key" { send "\r" }
expect "Enter passphrase" { send "\r" }
expect "Enter same passphrase agai" { send "\r" }
expect eof
!
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
exit 0
EOF
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
sed -i 's/^#[ \t]*\(%wheel[ \t]*ALL=(ALL)[ \t]*NOPASSWD:[ \t]*ALL\)$/\1/g' /etc/sudoers
usermod -aG wheel gpadmin

wget https://github.com/greenplum-db/gpdb/releases/download/6.0.1/greenplum-db-6.0.1-rhel7-x86_64.rpm -O greenplum-db-6.0.1.rpm && sudo yum install -y ./greenplum-db-6.0.1.rpm

cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

exit 0
