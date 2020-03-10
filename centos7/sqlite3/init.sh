path="/usr/local/sqlite3"
yum install -y wget gcc gcc-c++ make zlib zlib-devel libffi libffi-devel openssl openssl-devel
wget -c https://www.sqlite.org/2020/sqlite-autoconf-3310100.tar.gz -O sqlite-autoconf-3310100.tar.gz && tar -zxvf sqlite-autoconf-3310100.tar.gz && cd sqlite-autoconf-3310100 && CFLAGS="-Os -DSQLITE_THREADSAFE=2" ./configure --prefix=${path}&& make -j8 && make install && cd .. && rm -rf sqlite-autoconf-3310100*
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
mv /usr/bin/sqlite3  /usr/bin/sqlite3_old
ln -s ${path}/bin/sqlite3 /usr/bin/sqlite3
echo "${path}/lib/" >> /etc/ld.so.conf.d/sqlite3.conf && ldconfig

exit 0
