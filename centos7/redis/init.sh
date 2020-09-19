path="/usr/local/redis"
redis_ver="5.0.8"
_password="96515.cc"

while getopts "p:" opt
do
	case $opt in
		p)
		_password=$OPTARG ;;
		?)
		echo "Usage of Options:"
		echo "-p password"
		exit 1;;
	esac
done

workhome=`cd $(dirname $0); pwd -P`
cd $workhome

yum install -y wget gcc make automake expect
 # gcc-c++ make zlib zlib-devel libffi libffi-devel openssl openssl-devel
wget -c http://download.redis.io/releases/redis-${redis_ver}.tar.gz -O redis-${redis_ver}.tar.gz
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
tar -zxvf redis-${redis_ver}.tar.gz && cd redis-${redis_ver}
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
processor=`expr \`grep processor /proc/cpuinfo 2>&1 | wc -l\` \* 3 / 4 + 1`
make -j $processor && make install PREFIX=${path}
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
sed -i "s|^\(bind.*\)$|#\1|g" ${path}/conf/redis.conf
sed -i "s|^.*\(daemonize[[:blank:]]\)[a-z]*$|\1 yes|g" redis.conf
sed -i "s|^.*\(protected-mode[[:blank:]]\)[a-z]*$|\1 no|g" redis.conf
sed -i "s|^[#]*[[:blank:]]\(requirepass[[:blank:]]\).*$|\1 ${_password}|g" redis.conf
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
