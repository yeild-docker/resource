# /bin/bash
_port=1080
_user='-'
_password=''

while getopts "p:U:P:" opt
do
	case $opt in
		p)
		_port=$OPTARG ;;
		U)
		_user=$OPTARG ;;
		P)
		_password=$OPTARG ;;
		?)
		echo "Usage of Options:"
		echo "-p port"
		echo "-U username"
		echo "-P password"
		exit 1;;
	esac
done

[[ $_user != '-' ]] && [[ $_password = '' ]] && echo 'password unspecified' && exit 1

source /etc/profile

workhome=`cd $(dirname $0); pwd -P`
cd $workhome

which ss5 >> /dev/null 2>&1
if [ $? -ne 0 ]; then
	yum -y install gcc gcc-c++ automake make pam-devel openldap-devel cyrus-sasl-devel openssl-devel
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
	version=ss5-3.8.9
	wget http://sourceforge.net/projects/ss5/files/ss5/3.8.9-8/ss5-3.8.9-8.tar.gz -O $version.tar.gz
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
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
