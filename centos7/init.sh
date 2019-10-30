#!/bin/sh

yum provides '*/applydeltarpm' && yum install deltarpm -y
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
yum update -y
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

# timezone
curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/locale/init.sh" | sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

# sshd
curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/sshd/init.sh" | sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

#nginx
curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/nginx/init.sh" | sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

yum clean all && rm -rf /var/cache/yum/*

echo "Done"
exit 0
