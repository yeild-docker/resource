
# _VERSION=-19.03.4
_VERSION=""
_CENTOS=`sed -n "s|^.*CentOS[[:blank:]]*release[[:blank:]]*\([0-9]*\)\..*$|\1|p" /etc/redhat-release`

while getopts ":hv:" opt
do
	case $opt in
		h)
		echo "Usage of Options:"
		echo "-h help"
		echo "-v install a specific version of Docker"
			;;
		v)
		_VERSION="-$OPTARG" ;;
		?)
		echo "Unsurpoted Option -${opt}"
		exit 1;;
	esac
done

case $_CENTOS in
	6)
	rpm -iUvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
	yum update -y
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
	yum -y install docker-io
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
	chkconfig docker on
	service docker start
	;;
	7)
	yum install -y yum-utils device-mapper-persistent-data lvm2
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
	yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
	echo "To install a specific version of Docker Engine - Community, list the available versions in the repo, then select and install"
	echo "List and sort the versions available in your repo. This example sorts results by version number, highest to lowest, and is truncated:"
	echo "yum list docker-ce --showduplicates | sort -r"
	yum install -y docker-ce$_VERSION docker-ce-cli$_VERSION containerd.io
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then echo "Exit with Fail!"; exit $cmd_rs; fi
	systemctl enable docker
	systemctl start docker
	;;
esac
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
if ! [[ `sysctl net.ipv4.ip_forward` =~ net\.ipv4\.ip_forward[[:blank:]]=[[:blank:]]1 ]]; then
	echo -e "\nnet.ipv4.ip_forward=1\n" >> /etc/sysctl.conf && systemctl restart network
fi

exit 0

