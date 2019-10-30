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
curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/sshd/init.sh" | sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

# mwget
wget http://jaist.dl.sourceforge.net/project/kmphpfm/mwget/0.1/mwget_0.1.0.orig.tar.bz2 && tar -xjvf mwget_0.1.0.orig.tar.bz2 && cd mwget_0.1.0.orig && ./configure && make && make install && cd .. && rm -rf mwget_0.1.0.orig*
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

#nginx
curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/nginx/init.sh" | sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

yum clean all && rm -rf /var/cache/yum/*

echo "Done"
exit 0
