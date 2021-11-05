path="/usr/local/sqlite3"
openssl="/usr/local/openssl"

workhome=`cd $(dirname $0); pwd -P`
cd $workhome

yum install -y wget gcc gcc-c++ make zlib zlib-devel libffi libffi-devel
sqlite3_ver=3360000
if [ ! -d $openssl ]; then
	echo "Install openssl to ${openssl}"
	curl -fsSL "https://gitee.com/yeildi/script-resource/raw/master/centos7/openssl/init.sh" | sh
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
wget --no-check-certificate -c https://www.sqlite.org/2021/sqlite-autoconf-${sqlite3_ver}.tar.gz -O sqlite-autoconf-${sqlite3_ver}.tar.gz
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
tar -zxvf sqlite-autoconf-${sqlite3_ver}.tar.gz && cd sqlite-autoconf-${sqlite3_ver}
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
CFLAGS="-Os -DSQLITE_THREADSAFE=2" ./configure --prefix=${path}
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
processor=`expr \`grep processor /proc/cpuinfo 2>&1 | wc -l\` \* 3 / 4 + 1`
make -j $processor && make install
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
cd .. && rm -rf sqlite-autoconf-${sqlite3_ver}*
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
if [[ ! "`grep "export LIBRARY_PATH=.*${path}/lib.*" /etc/profile`" ]]; then
	echo "export LIBRARY_PATH=\$LIBRARY_PATH:${path}/lib" >> /etc/profile
	source /etc/profile
fi

exit 0
