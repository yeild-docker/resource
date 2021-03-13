path="/usr/local/python3"
openssl="/usr/local/openssl"
sqlite3="/usr/local/sqlite3"
with_openssl="--with-openssl=${openssl}"
python_version=3.7.9

workhome=`cd $(dirname $0); pwd -P`
cd $workhome
source /etc/profile

if [ ! -d $openssl ]; then
	echo "Install openssl to ${openssl}"
	curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/openssl/init.sh" | sh
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
if [ ! -d $sqlite3 ]; then
	echo "Install sqlite3 to ${sqlite3}"
	curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/sqlite3/init.sh" | sh
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
yum install -y wget gcc gcc-c++ make zlib zlib-devel libffi libffi-devel expat expat-devel
# wget -c https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz -O Python-${python_version}.tgz
curl -C -O https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz -o Python-${python_version}.tgz
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
tar -zxvf Python-${python_version}.tgz && cd Python-${python_version}
./configure LDFLAGS="-L${openssl}/lib -L${sqlite3}/lib" CPPFLAGS="-I${sqlite3}/include" --enable-shared --enable-optimizations --enable-loadable-sqlite-extensions --with-system-expat --with-system-ffi --with-ensurepip=yes --prefix=${path} ${with_openssl}
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
processor=`expr \`grep processor /proc/cpuinfo 2>&1 | wc -l\` \* 2 / 3 + 1`
make -j $processor && make install
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
cd .. && rm -rf Python-${python_version}*
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
ln -s ${path}/bin/python3 /usr/bin/python3 && ln -s ${path}/bin/pip3 /usr/bin/pip3
if [[ ! "`grep "${path}/lib/.*" /etc/ld.so.conf`" ]]; then
	echo "${path}/lib/" >> /etc/ld.so.conf && ldconfig
fi

if [[ ! "`grep "export PATH=.*${path}/bin.*" /etc/profile`" ]]; then
	echo "export PATH=\$PATH:${path}/bin" >> /etc/profile
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

exit 0
