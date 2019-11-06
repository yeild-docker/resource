
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
if [[ ! "`grep '^export[[:blank:]]*LC_ALL=en_US.UTF-8$' /etc/profile`" ]]; then
	echo "export LC_ALL=en_US.UTF-8" >> /etc/profile && source /etc/profile
fi
if [[ ! "`grep '^export[[:blank:]]*LANG=zh_CN.UTF-8$' /etc/profile`" ]]; then
	echo "export LANG=zh_CN.UTF-8" >> /etc/profile && source /etc/profile
fi
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
if [[ ! "`grep '^source[[:blank:]]*/etc/profile$' /root/.bashrc`" ]]; then
	echo "source /etc/profile" >> /root/.bashrc && source /root/.bashrc
fi

exit 0
