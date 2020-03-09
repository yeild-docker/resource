
nginx_path=/usr/local/nginx
yum install -y wget gcc gcc-c++ make pcre pcre-devel zlib zlib-devel
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

wget https://nginx.org/download/nginx-1.16.1.tar.gz -O nginx-1.16.1.tar.gz && tar -zxvf nginx-1.16.1.tar.gz && cd nginx-1.16.1 && ./configure --prefix=$nginx_path && make && make install && echo "export PATH=/usr/local/nginx/sbin:\$PATH" >> /etc/profile && source /etc/profile && cd .. && rm -rf nginx-1.16.1*
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

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
#ExecStartPre=/usr/bin/rm -f ${nginx_path}/logs/nginx.pid
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
exit 0