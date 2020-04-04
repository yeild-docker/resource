path="/usr/local/frp"

wget -c https://github.com/fatedier/frp/releases/download/v0.32.1/frp_0.32.1_linux_amd64.tar.gz -O frp.tar.gz
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
tar -zxvf frp.tar.gz && \mv -f ./frp $path
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
cd $path

if [[ ! "`grep "export PATH=.*${path}.*" /etc/profile`" ]]; then
	echo "export PATH=${path}:\$PATH" >> /etc/profile
	source /etc/profile
fi
  cat << EOF > "frps.ini"
[common]
bind_addr = 0.0.0.0
bind_port = 7000
vhost_http_port = 7000
subdomain_host = local.yeild.top
# authentication_method = token
# token = yeild
# authenticate_heartbeats = true
# authenticate_new_work_conns = true

# dashboard_addr = 0.0.0.0
# dashboard_port = 7500
# dashboard_user = admin
# dashboard_pwd = 96515.cc

EOF
  cat << EOF > "frps.ini"
[common]
server_addr = 218.6.196.133
server_port = 7000
# authentication_method = token
# token = yeild

[yb]
type = http
local_ip = 127.0.0.1
local_port = 80
subdomain = apis-yb
use_compression = true

EOF

sys_version=`cat /etc/$system-release|awk '{print $(NF-1)}'|awk -F . '{print $1"."$2}'`
if [[ "$sys_version" == 6.* ]]; then
	echo "Add Frp Control to service"
  cat << EOF > "/etc/init.d/frps"
#!/bin/bash
#
# Frp Server Service
# chkconfig: 2345 10 90
#

start() {
	cd ${path}
	if [ -f frps.pid ]; then
		return 0
	fi
 	/usr/bin/nohup ${path}/frps -c ${path}/frps.ini > frps.log 2>&1 &
 	echo \$! > frps.pid
 	return $?
}

stop() {
	kill -9 \`cat ${path}/frps.pid\`
	rm -rf ${path}/frps.pid
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
*)
        echo "Usage:service frps {start|stop|restart}" >&2
esac
EOF
	chmod 777 /etc/init.d/frps
	chkconfig --add /etc/init.d/frps
	service frps start
elif [[ "$sys_version" == 7.* ]]; then
cat << EOF > "/lib/systemd/system/frps.service"
[Unit]
Description=Frp Server Service
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStartPre=cd ${path}
ExecStart=/usr/bin/nohup ${path}/frps -c ${path}/frps.ini >> frps.log 2>&1 &
ExecStop=ps aux|grep frps.ini|grep -v grep|awk '{print $2}'|xargs kill -9

[Install]
WantedBy=multi-user.target

EOF
	chmod 755 /lib/systemd/system/frps.service
	systemctl enable frps
	systemctl start frps
fi

exit 0
