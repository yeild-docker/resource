path="/usr/local/python3"
openssl="/usr/local/openssl"
with_openssl="--with-openssl=${openssl}"

if [ ! -d $openssl ]; then
	echo "Install openssl to ${openssl}"
	curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/openssl/init.sh" | sh
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
yum install -y wget gcc gcc-c++ make zlib zlib-devel libffi libffi-devel openssl openssl-devel
wget -c https://www.python.org/ftp/python/3.7.6/Python-3.7.6.tgz -O Python-3.7.6.tgz && tar -zxvf Python-3.7.6.tgz && cd Python-3.7.6 && ./configure --enable-shared --enable-optimizations --prefix=${path} ${with_openssl} && make -j8 && make install && cd .. && rm -rf Python-3.7.6*
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
ln -s ${path}/bin/python3 /usr/bin/python3 && ln -s ${path}/bin/pip3 /usr/bin/pip3
if [[ ! "`grep "${path}/lib/.*" /etc/ld.so.conf`" ]]; then
	echo "${path}/lib/" >> /etc/ld.so.conf && ldconfig
fi

if [[ ! "`grep "export PATH=.*${path}/bin.*" /etc/profile`" ]]; then
	echo "export PATH=\$PATH:${path}/bin" >> /etc/profile
	source /etc/profile
fi

exit 0
