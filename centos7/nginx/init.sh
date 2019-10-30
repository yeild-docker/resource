
yum install -y wget gcc gcc-c++ automake autoconf libtool make openssl openssl-devel expect
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

wget https://nginx.org/download/nginx-1.16.1.tar.gz && tar -zxvf nginx-1.16.1.tar.gz && cd nginx-1.16.1 && ./configure --prefix=/usr/local/nginx && make && make install && echo "export PATH=/usr/local/nginx/sbin:\$PATH" >> /etc/profile && source /etc/profile && cd .. && rm -rf nginx-1.16.1* && wget -P /lib/systemd/system https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/nginx/nginx.service && systemctl enable nginx
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
systemctl start nginx
exit 0