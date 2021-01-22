#!/bin/bash
_PASSWORD=""

while getopts ":hp:" opt
do
	case $opt in
		h)
		echo "Usage of Options:"
		echo "-h help"
		echo "-p password of root user."
			;;
		p)
		_PASSWORD=$OPTARG ;;
		?)
		echo "Unsurported Option -${opt}"
		exit 1 ;;
	esac
done

workhome=`cd $(dirname $0); pwd -P`
cd $workhome

yum install -y openssh-server openssh-clients passwd cracklib-dicts expect
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

if [[ "$_PASSWORD" -ne "" ]]; then
	echo root:$_PASSWORD | chpasswd
fi

exit 0
