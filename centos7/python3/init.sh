path="/usr/local/python3"
openssl="/usr/local/openssl"
sqlite3="/usr/local/sqlite3"
with_openssl="--with-openssl=${openssl}"
python_version=3.9.9

_required_packages='wget gcc gcc-c++ make zlib zlib-devel libffi libffi-devel expat expat-devel'
_trans_args=""
_run_mode="normal"
_with_upgrade=0

args_help=$(cat <<- EOF
$0 参数说明：
    -U 升级
    -offline 离线安装，使用--download下载的文件安装
    -download 下载安装文件以供离线安装
错误详情
EOF
)
echo "$@"
ARGS=`getopt -o U --long offline,download -n "$args_help" -- "$@"`
if [ $? != 0 ]; then exit 1 ; fi
echo "args1 ${ARGS}"
eval set -- "${ARGS}"
if [ $? != 0 ]; then exit 1 ; fi
echo "args2 ${ARGS}"
while true
do
    case "$1" in
        -U)
            _with_upgrade=1 ;
			_trans_args="$_trans_args -U";
			shift ;;
        --offline)
            _run_mode="offline" ;
			_trans_args="$_trans_args --offline";
			 shift ;;
        --download)
            _run_mode="download" ;
			_trans_args="$_trans_args --download";
			 shift ;;
        --) shift; break ;;
        *)
            echo "参数读取错误" ; exit 1 ;;
    esac
done

workhome=`cd $(dirname $0); pwd -P`
cd $workhome
source /etc/profile

if [[ $_run_mode = "download" ]]; then
	# yum install --downloadonly --downloaddir=./yumpackages -y $_required_packages
	curl -fsSL "https://gitee.com/yeildi/script-resource/raw/master/centos7/openssl/init.sh" -o openssl.sh
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	sh openssl.sh -s -- $_trans_args
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	curl -fsSL "https://gitee.com/yeildi/script-resource/raw/master/centos7/sqlite3/init.sh" -o sqlite3.sh
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	sh sqlite3.sh -s -- $_trans_args
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	wget -c https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz -O Python-${python_version}.tgz
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	exit 0
fi

if [[ ! -d $openssl || $_with_upgrade = 1 ]]; then
	echo "Install openssl to ${openssl}"
	if [ $_run_mode = "offline" ]; then
		sh openssl.sh -s -- $_trans_args
	else
		curl -fsSL "https://gitee.com/yeildi/script-resource/raw/master/centos7/openssl/init.sh" | sh -s -- $_trans_args
	fi
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
if [[ ! -d $sqlite3 || $_with_upgrade = 1 ]]; then
	echo "Install sqlite3 to ${sqlite3}"
	if [ $_run_mode = 'offline' ]; then
		sh openssl.sh -s -- $_trans_args
	else
		curl -fsSL "https://gitee.com/yeildi/script-resource/raw/master/centos7/sqlite3/init.sh" | sh -s -- $_trans_args
	fi
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi

cur_python_v=`python3 -V 2>&1`
if [[ $? = 0 ]]; then
	cur_python_v=${cur_python_v#* }
	if [[ $_with_upgrade = 1 && $cur_python_v = $python_version ]]; then
		echo 'Python Already installed.'
		exit 0
	fi
fi

yum install -y $_required_packages
if [[ ! $_run_mode = "offline" ]]; then
	wget -c https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz -O Python-${python_version}.tgz
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
tar -zxvf Python-${python_version}.tgz && cd Python-${python_version}
#  --enable-optimizations
./configure LDFLAGS="-L${openssl}/lib -L${sqlite3}/lib" CPPFLAGS="-I${sqlite3}/include" --enable-shared --enable-loadable-sqlite-extensions --enable-optimizations --with-system-expat --with-system-ffi --with-ensurepip=yes --with-lto --prefix=${path} ${with_openssl}
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
