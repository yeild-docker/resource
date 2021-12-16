path="/usr/local/redis"
redis_ver="5.0.9"
_password=""

 # gcc-c++ make zlib zlib-devel libffi libffi-devel openssl openssl-devel
_required_packages='wget gcc make automake expect'
_trans_args=""
_run_mode="normal"
_with_upgrade=0

args_help=$(cat <<- EOF
$0 参数说明：
    -p password
    -U 升级
    --offline 离线安装，使用--download下载的文件安装
    --download 下载安装文件以供离线安装
错误详情
EOF
)
ARGS=`getopt -o Up: --long offline,download -n "$args_help" -- "$@"`
if [ $? != 0 ]; then exit 1 ; fi
eval set -- "${ARGS}"
while true
do
    case "$1" in
        -p)
            _password=$2 ;
			shift 2 ;;
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
	wget --no-check-certificate -c http://download.redis.io/releases/redis-${redis_ver}.tar.gz -O redis-${redis_ver}.tar.gz
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	exit 0
fi

cur_redis_v=`redis-server -v 2>&1`
if [[ $? = 0 ]]; then
	cur_redis_v=${cur_redis_v#*v=}
	cur_redis_v=${cur_redis_v%% *}
	if [[ $_with_upgrade = 1 && $cur_redis_v = $redis_ver ]]; then
		echo "Redis Already installed."
		exit 0
	fi
fi

yum install -y $_required_packages
if [[ ! $_run_mode = "offline" ]]; then
	wget --no-check-certificate -c http://download.redis.io/releases/redis-${redis_ver}.tar.gz -O redis-${redis_ver}.tar.gz
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
tar -zxvf redis-${redis_ver}.tar.gz && cd redis-${redis_ver}
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
processor=`expr \`grep processor /proc/cpuinfo 2>&1 | wc -l\` \* 3 / 4 + 1`
make -j $processor && make install PREFIX=${path}
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
sed -i "s|^\(bind.*\)$|#\1|g" redis.conf
sed -i "s|^.*\(daemonize[[:blank:]]\)[a-z]*$|\1 yes|g" redis.conf
sed -i "s|^.*\(protected-mode[[:blank:]]\)[a-z]*$|\1 no|g" redis.conf
if [[ "$_password" -ne "" ]]; then
	sed -i "s|^[#]*[[:blank:]]\(requirepass[[:blank:]]\).*$|\1 ${_password}|g" redis.conf
fi
if [[ ! -d ${path}/conf ]]; then
	mkdir -p ${path}/conf && cp -p redis.conf ${path}/conf/
	cd utils
	expect<<!
	spawn ./install_server.sh
	expect {
		"Please select the redis port" { send "6379\r"; exp_continue; }
		"Please select the redis config file" { send "${path}/conf/redis.conf\r"; exp_continue; }
		"Please select the redis log file" { send "${path}/logs/redis_6379.log\r"; exp_continue; }
		"Please select the data directory" { send "${path}/data/6379\r"; exp_continue; }
		"Please select the redis executable" { send "${path}/bin/redis-server\r"; exp_continue; }
		"Is this ok" { send "\r"; exp_continue; }
		eof
	}
!
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	cd ..
fi
cd .. && rm -rf redis-${redis_ver}*

if [[ ! "`grep "export PATH=.*${path}/bin.*" /etc/profile`" ]]; then
	echo "export PATH=\$PATH:${path}/bin" >> /etc/profile
	source /etc/profile
fi
mv /etc/init.d/redis_6379 ${path}/bin/redisd
cat <<- EOF > "/usr/lib/systemd/system/redisd.service"
    [Unit]
    Description=Redis Server with Port 6379

    [Service]
    Type=forking
    Restart=always
    RestartSec=30
    ExecStart=${path}/bin/redisd start
    ExecReload=${path}/bin/redisd restart
    ExecStop=${path}/bin/redisd stop
    TimeoutStopSec=5
    KillMode=process
    PrivateTmp=false

    [Install]
    WantedBy=multi-user.target
EOF
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
systemctl enable redisd

echo "Install Redis to '${path}' Successed!"
echo "`redis-server -v`"
echo "Start the redis with 'systemctl start redisd'"

exit 0
