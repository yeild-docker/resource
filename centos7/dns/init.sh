# /bin/bash
source /etc/profile

workhome=`cd $(dirname $0); pwd -P`
cd $workhome

yum install bind bind-utils -y
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
sed -i "s|^\(.*listen-on port 53 { \)[^;]*\(; };\)$|\1any\2|g" /etc/named.conf
sed -i "s|^\([^/]*\)\(allow-query.*\)$|\1/* \2 */|g" /etc/named.conf
named-checkconf /etc/named.conf
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

firewall-cmd --zone=public --add-port=53/udp --permanent
firewall-cmd --zone=public --add-port=53/tcp --permanent
firewall-cmd --reload

systemctl enable named
systemctl start named
