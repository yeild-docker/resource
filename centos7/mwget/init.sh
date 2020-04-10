
workhome=`cd $(dirname $0); pwd -P`
cd $workhome

yum install -y wget gcc-c++ bzip2 intltool make openssl openssl-devel
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

wget http://jaist.dl.sourceforge.net/project/kmphpfm/mwget/0.1/mwget_0.1.0.orig.tar.bz2 -O mwget_0.1.0.orig.tar.bz2 && tar -xjvf mwget_0.1.0.orig.tar.bz2 && cd mwget_0.1.0.orig && ./configure && make && make install && cd .. && rm -rf mwget_0.1.0.orig*
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

exit 0
