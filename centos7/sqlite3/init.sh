path="/usr/local/sqlite3"
openssl="/usr/local/openssl"

yum install -y wget gcc gcc-c++ make zlib zlib-devel libffi libffi-devel
sqlite3_ver=3310100
if [ ! -d $openssl ]; then
	echo "Install openssl to ${openssl}"
	curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/openssl/init.sh" | sh
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
wget -c https://www.sqlite.org/2020/sqlite-autoconf-${sqlite3_ver}.tar.gz -O sqlite-autoconf-${sqlite3_ver}.tar.gz && tar -zxvf sqlite-autoconf-${sqlite3_ver}.tar.gz && cd sqlite-autoconf-${sqlite3_ver} && CFLAGS="-Os -DSQLITE_THREADSAFE=2" ./configure --prefix=${path}&& make -j8 && make install && cd .. && rm -rf sqlite-autoconf-${sqlite3_ver}*
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
mv /usr/bin/sqlite3  /usr/bin/sqlite3_old
ln -s ${path}/bin/sqlite3 /usr/bin/sqlite3

if [[ ! "`grep "${path}/lib/.*" /etc/ld.so.conf.d/sqlite3.conf`" ]]; then
	echo "${path}/lib/" >> /etc/ld.so.conf.d/sqlite3.conf && ldconfig
fi
if [[ ! "`grep "export LD_LIBRARY_PATH=.*${path}/lib.*" /etc/profile`" ]]; then
	echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${path}/lib" >> /etc/profile
	source /etc/profile
fi

exit 0
