path="/usr/local/openssl"
openssl_ver="1.1.1f"

yum install -y wget gcc make zlib zlib-devel
wget -c http://www.openssl.org/source/openssl-${openssl_ver}.tar.gz -O openssl-${openssl_ver}.tar.gz && tar -zxvf openssl-${openssl_ver}.tar.gz && cd openssl-${openssl_ver} && ./config --prefix=${path} shared zlib && make && make install && cd .. && rm -rf openssl-${openssl_ver}*
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

if [[ ! "`grep "export PATH=.*${path}/bin.*" /etc/profile`" ]]; then
	echo "export PATH=${path}/bin/:\$PATH" >> /etc/profile
	source /etc/profile
fi
if [[ ! "`grep "export LD_LIBRARY_PATH=.*${path}/lib.*" /etc/profile`" ]]; then
	echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${path}/lib" >> /etc/profile
	source /etc/profile
fi
if [[ ! "`grep "export LIBRARY_PATH=.*${path}/lib.*" /etc/profile`" ]]; then
	echo "export LIBRARY_PATH=\$LIBRARY_PATH:${path}/lib" >> /etc/profile
	source /etc/profile
fi
ln -s ${path}/lib/libssl.so.1.1 /usr/lib64/libssl.so.1.1
ln -s ${path}/lib/libcrypto.so.1.1 /usr/lib64/libcrypto.so.1.1

exit 0
