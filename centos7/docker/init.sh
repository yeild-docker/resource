
# _VERSION=-19.03.4
_VERSION=""
_DOCKER=0

while getopts ":hdv" opt
do
	case $opt in
		h)
		echo "Usage of Options:"
		echo "-h help"
		echo "-d run from docker"
		echo "-v install a specific version of Docker"
			;;
		d)
		_DOCKER=$OPTARG ;;
		v)
		_VERSION=$OPTARG ;;
		?)
		echo "Unsurpoted Option -${opt}"
		exit 1;;
	esac
done

yum install -y yum-utils device-mapper-persistent-data lvm2
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
echo "To install a specific version of Docker Engine - Community, list the available versions in the repo, then select and install"
echo "List and sort the versions available in your repo. This example sorts results by version number, highest to lowest, and is truncated:"
echo "yum list docker-ce --showduplicates | sort -r"
yum install -y docker-ce$_VERSION docker-ce-cli$_VERSION containerd.io
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

systemctl enable docker
systemctl start docker

exit 0

