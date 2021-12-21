path="/usr/local/sqlite3"
openssl="/usr/local/openssl"
sqlite3_v=3.37.0
sqlite3_ver=3370000

_required_packages='wget gcc gcc-c++ make zlib zlib-devel libffi libffi-devel'
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

if [[ $_run_mode = "download" ]]; then
    curl -fsSL "https://gitee.com/yeildi/script-resource/raw/master/centos7/openssl/init.sh" -o openssl.sh
    cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
    bash openssl.sh $_trans_args
    cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
    wget --no-check-certificate -c https://www.sqlite.org/2021/sqlite-autoconf-${sqlite3_ver}.tar.gz -O sqlite-autoconf-${sqlite3_ver}.tar.gz
    cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
    exit 0
fi
source /etc/profile

yum install -y $_required_packages
if [[ ! -d $openssl || $_with_upgrade = 1 ]]; then
    echo "Install openssl to ${openssl}"
    if [ $_run_mode = "offline" ]; then
        bash openssl.sh $_trans_args
    else
        curl -fsSL "https://gitee.com/yeildi/script-resource/raw/master/centos7/openssl/init.sh" | bash -s -- $_trans_args
    fi
    cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi

cur_sqlite_v=`sqlite3 --version 2>&1`
if [[ $? = 0 ]]; then
    cur_sqlite_v=${cur_sqlite_v%% *}
    if [[ $_with_upgrade = 1 && $cur_sqlite_v = $sqlite3_v ]]; then
        echo "Sqlite Already installed."
        exit 0
    fi
fi

if [[ ! $_run_mode = "offline" ]]; then
    wget --no-check-certificate -c https://www.sqlite.org/2021/sqlite-autoconf-${sqlite3_ver}.tar.gz -O sqlite-autoconf-${sqlite3_ver}.tar.gz
    cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
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
