path="/usr/local/python3"
openssl="/usr/local/openssl"
with_openssl="--with-openssl=${openssl}"

if [ ! -d $openssl ]; then
	echo "Install openssl to ${openssl}"
	curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/openssl/init.sh" | sh
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
yum install -y wget gcc make zlib zlib-devel
wget -c https://www.python.org/ftp/python/3.7.5/Python-3.7.5.tgz -O Python-3.7.5.tgz && tar -zxvf Python-3.7.5.tgz && cd Python-3.7.5 && ./configure --prefix=${path} ${with_openssl} && make && make install && cd .. && rm -rf Python-3.7.5* && ln -s ${path}/bin/python3 /usr/bin/python3 && ln -s ${path}/bin/pip3 /usr/bin/pip3
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

exit 0
