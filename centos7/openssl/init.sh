path="/usr/local/openssl"
openssl_ver="1.1.1l"

_required_packages='wget gcc make zlib zlib-devel perl'
_trans_args=""
_run_mode="normal"
_with_upgrade=0

args_help=$(cat <<- EOF
$0 参数说明：
    -U 升级
    --offline 离线安装，使用--download下载的文件安装
    --download 下载安装文件以供离线安装
错误详情
EOF
)
ARGS=`getopt -o U --long offline,download -n "$args_help" -- "$@"`
if [ $? != 0 ]; then exit 1 ; fi
eval set -- "${ARGS}"
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
    wget --no-check-certificate -c https://www.openssl.org/source/openssl-${openssl_ver}.tar.gz -O openssl-${openssl_ver}.tar.gz
    cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
    exit 0
fi

cur_openssl_ver=`openssl version 2>&1`
if [[ $? = 0 ]]; then
    cur_openssl_ver=${cur_openssl_ver#* }
    cur_openssl_ver=${cur_openssl_ver%% *}
    if [[ $_with_upgrade = 1 && $cur_openssl_ver = $openssl_ver ]]; then
        echo 'Openssl Already installed.'
        exit 0
    fi
fi

yum install -y $_required_packages
if [[ ! $_run_mode = "offline" ]]; then
    wget --no-check-certificate -c https://www.openssl.org/source/openssl-${openssl_ver}.tar.gz -O openssl-${openssl_ver}.tar.gz
    cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
tar -zxvf openssl-${openssl_ver}.tar.gz && cd openssl-${openssl_ver}
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
./config --prefix=${path} shared zlib
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
processor=`expr \`grep processor /proc/cpuinfo 2>&1 | wc -l\` \* 3 / 4 + 1`
make -j $processor && make install
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
cd .. && rm -rf openssl-${openssl_ver}*
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
