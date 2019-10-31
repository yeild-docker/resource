path=/usr/local/python3

yum install -y wget gcc make zlib zlib-devel
wget https://www.python.org/ftp/python/3.7.5/Python-3.7.5.tgz -O Python-3.7.5.tgz && tar -zxvf Python-3.7.5.tgz && cd Python-3.7.5 && ./configure -prefix=$path && make && make install && cd .. && rm -rf Python-3.7.5* && ln -s $path/bin/python3 /usr/bin/python3 && ln -s $path/bin/pip3 /usr/bin/pip3
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

exit 0
