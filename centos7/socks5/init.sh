# /bin/bash
_port=1080
_user='-'
_password=''
version=ss5-3.8.9
wget_file_opts="--no-check-certificate -c http://sourceforge.net/projects/ss5/files/ss5/3.8.9-8/ss5-3.8.9-8.tar.gz -O $version.tar.gz"

_required_packages='gcc gcc-c++ automake make pam-devel openldap-devel cyrus-sasl-devel openssl-devel'
_trans_args=""
_run_mode="normal"
_with_upgrade=0

args_help=$(cat <<- EOF
$0 参数说明：
    -p port
    -U username
    -P password
    --offline 离线安装，使用--download下载的文件安装
    --download 下载安装文件以供离线安装
错误详情
EOF
)
ARGS=`getopt -o p:U:P: --long offline,download -n "$args_help" -- "$@"`
if [ $? != 0 ]; then exit 1 ; fi
eval set -- "${ARGS}"
while true
do
    case "$1" in
        -p)
            _port=$2 ;
            shift 2 ;;
        -U)
            _user=$2 ;
            shift 2 ;;
        -P)
            _password=$2 ;
            shift 2 ;;
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

[[ $_user != '-' ]] && [[ $_password = '' ]] && echo 'password unspecified' && exit 1

source /etc/profile

workhome=`cd $(dirname $0); pwd -P`
cd $workhome

if [[ $_run_mode = "download" ]]; then
    wget $wget_file_opts
    cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
    exit 0
fi

which ss5 >> /dev/null 2>&1
if [ $? -ne 0 ]; then
	yum -y install $_required_packages
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
    if [[ ! $_run_mode = "offline" ]]; then
		wget $wget_file_opts
		cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	fi
	tar zxvf $version.tar.gz && cd $version && ./configure && make && make install && cd .. && rm -rf $version
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
auth='-' && [[ $_user != '-' ]] && auth='u'
sed -i "s|^#.*\(auth[^0]*0\.0\.0\.0/0[^-]*-[^-]*\)-\(.*\)$|\1$auth\2|g" /etc/opt/ss5/ss5.conf
sed -i "s|^#.*\(permit[^-]*\)-\([^0]*0\.0\.0\.0/0[^-]*-[^0]*0\.0\.0\.0/0[^-]*-.*\)$|\1$auth\2|g" /etc/opt/ss5/ss5.conf

[[ $_user != '-' ]] && [[ ! "`grep "^$_user .*" /etc/opt/ss5/ss5.passwd`" ]] && echo "$_user $_password" >> /etc/opt/ss5/ss5.passwd

sed -i "s|#*\(SS5_OPTS=\" -u root\).*\"|\1 -b 0.0.0.0:$_port\"|g" /etc/sysconfig/ss5

firewall-cmd --zone=public --add-port=$_port/tcp --permanent
firewall-cmd --reload

chmod a+x /etc/init.d/ss5
chkconfig --add ss5
chkconfig ss5 on
systemctl start ss5

auth="" && [[ $_user != '-' ]] && auth="$_user:$_password@"
echo "Usage example: export ALL_PROXY=\"socks5://${auth}{本机IP}:$_port\"'"
