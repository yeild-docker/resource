yum install ntp ntpdate -y
firewall-cmd --zone=public --add-port=123/udp --permanent
firewall-cmd --reload
[[ ! "`grep "server 127.127.1.0" /etc/ntp.conf`" ]] && echo "server 127.127.1.0" >> /etc/ntp.conf
[[ ! "`grep "fudge  127.127.1.0  stratum 10" /etc/ntp.conf`" ]] && echo "fudge  127.127.1.0  stratum 10" >> /etc/ntp.conf
systemctl enable ntpd
systemctl start ntpd
