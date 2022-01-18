nginx_path=/usr/local/nginx
openssl="/usr/local/openssl"
nginx_ver=1.21.4
pack_file=nginx-${nginx_ver}
wget_file_opts="--no-check-certificate -c https://nginx.org/download/nginx-${nginx_ver}.tar.gz -O ${pack_file}.tar.gz"

_required_packages='wget gcc gcc-c++ make pcre pcre-devel zlib zlib-devel'
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
    wget $wget_file_opts
    cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
    exit 0
fi
source /etc/profile

if [[ ! -d $openssl || $_with_upgrade = 1 ]]; then
    echo "Install openssl to ${openssl}"
    if [ $_run_mode = "offline" ]; then
        bash openssl.sh $_trans_args
    else
        curl -fsSL "https://gitee.com/yeildi/script-resource/raw/master/centos7/openssl/init.sh" | bash -s -- $_trans_args
    fi
    cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi

cur_nginx_ver=`nginx -v 2>&1`
if [[ $? = 0 ]]; then
    cur_nginx_ver=${cur_nginx_ver#*/}
    if [[ $_with_upgrade = 1 && $cur_nginx_ver = $nginx_ver ]]; then
        echo "Nginx Already installed."
        exit 0
    fi
fi
if [ ! -d ${pack_file} ]; then
    yum install -y $_required_packages
    cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
    if [[ ! $_run_mode = "offline" ]]; then
        wget $wget_file_opts
        cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
    fi
    tar -zxvf ${pack_file}.tar.gz
    cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
cd ${pack_file}
sed -i 's|^\(.*$OPENSSL/\)\.openssl/\(.*\)$|\1\2|g' auto/lib/openssl/conf
./configure --prefix=$nginx_path --user=www --group=www --with-http_stub_status_module --with-http_sub_module --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_gunzip_module --with-http_gzip_static_module --with-stream --with-stream_ssl_module --with-openssl=${openssl} --with-openssl-opt='enable-weak-ssl-ciphers'
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
processor=`expr \`grep processor /proc/cpuinfo 2>&1 | wc -l\` \* 3 / 4 + 1`
make -j $processor && make install
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
cd .. && rm -rf ${pack_file}*
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

if [[ ! "`grep "export PATH=.*$nginx_path/sbin.*" /etc/profile`" ]]; then
    echo "export PATH=$nginx_path/sbin:\$PATH" >> /etc/profile && source /etc/profile
fi

core=`uname -a`
# Darwin Linux
core=${core%% *}
if [ $core = "Linux" ]
  then
    if [ -e /etc/centos-release ];then
      system=centos
      yum install -y expect
   elif [ -e /etc/redhat-release ];then
     system=redhat
    else
      echo "Other liunx versions"
      exit 1
    fi
fi
sys_version=`cat /etc/$system-release|awk '{print $(NF-1)}'|awk -F . '{print $1"."$2}'`
if [[ "$sys_version" == 6.* ]]; then
    echo "Add Nginx Control to service"
  cat << EOF > "/etc/init.d/nginx"
#!/bin/bash
#
# Nginx control service
# chkconfig: 2345 10 90
#

start() {
  ${nginx_path}/sbin/nginx -t && ${nginx_path}/sbin/nginx
  return $?
}

stop() {
  ${nginx_path}/sbin/nginx -s stop
  return $?
}

case "\$1" in
start)
        start
        ;;

stop)
        stop
        ;;
restart)
        stop
        start
        ;;
reload)
        ${nginx_path}/sbin/nginx -t && ${nginx_path}/sbin/nginx -s reload
        ;;
*)
        echo "Usage:service nginx {start|stop|reload|restart}" >&2
esac
EOF
    chmod 777 /etc/init.d/nginx
    chkconfig --add /etc/init.d/nginx
    service nginx start
elif [[ "$sys_version" == 7.* ]]; then
    echo "Add Nginx Control to systemctl"
cat << EOF > "/lib/systemd/system/nginx.service"
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
LimitNOFILE=1048000
PIDFile=${nginx_path}/logs/nginx.pid
# Nginx will fail to start if ${nginx_path}/log/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running `nginx -t` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/usr/bin/rm -rf ${nginx_path}/logs/nginx.pid
ExecStartPre=${nginx_path}/sbin/nginx -t
ExecStart=${nginx_path}/sbin/nginx
ExecReload=${nginx_path}/sbin/nginx -s reload
ExecStop=${nginx_path}/sbin/nginx -s stop
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=process
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    chmod 755 /lib/systemd/system/nginx.service
    systemctl enable nginx
    systemctl start nginx
else
    exit 1
fi

exit 0
