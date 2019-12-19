path=/usr/local/openssl

yum install -y wget gcc make zlib zlib-devel
wget http://www.openssl.org/source/openssl-1.1.1.tar.gz -O openssl-1.1.1.tar.gz && tar -zxvf openssl-1.1.1.tar.gz && cd openssl-1.1.1 && ./configure -prefix=$path shared zlib && make && make install && cd .. && rm -rf openssl-1.1.1*
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${path}/lib" >> /etc/profile
source /etc/profile
ln -s $path/lib/libssl.so.1.1 /usr/lib64/libssl.so.1.1
ln -s $path/lib/libcrypto.so.1.1 /usr/lib64/libcrypto.so.1.1

exit 0