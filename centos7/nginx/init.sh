nginx_path=/usr/local/nginx
openssl="/usr/local/openssl"

workhome=`cd $(dirname $0); pwd -P`
cd $workhome

nginx_v=`nginx -v 2>&1`
if [ $? -ne 0 ]; then
	if [ ! -d $openssl ]; then
		echo "Install openssl to ${openssl}"
		curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/openssl/init.sh" | sh
		cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	fi
	nginx_ver=1.17.9
	yum install -y wget gcc gcc-c++ make pcre pcre-devel zlib zlib-devel
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	wget https://nginx.org/download/nginx-${nginx_ver}.tar.gz -O nginx-${nginx_ver}.tar.gz
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	tar -zxvf nginx-${nginx_ver}.tar.gz
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	sed -i 's|^\(.*$OPENSSL/\)\.openssl/\(.*\)$|\1\2|g' auto/lib/openssl/conf
	cd nginx-${nginx_ver}
	./configure --prefix=$nginx_path --user=www --group=www --with-http_stub_status_module --with-http_sub_module --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_gunzip_module --with-http_gzip_static_module --with-stream --with-stream_ssl_module --with-openssl=${openssl} --with-openssl-opt='enable-weak-ssl-ciphers'
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	processor=`expr \`grep processor /proc/cpuinfo 2>&1 | wc -l\` \* 3 / 4 + 1`
	make -j $processor && make install
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	cd .. && rm -rf nginx-${nginx_ver}*
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	
	if [[ ! "`grep "export PATH=.*$nginx_path/sbin.*" /etc/profile`" ]]; then
		echo "export PATH=$nginx_path/sbin:\$PATH" >> /etc/profile && source /etc/profile
	fi
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