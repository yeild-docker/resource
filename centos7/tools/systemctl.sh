#!/bin/bash

_service=""
_cmd_start=""
_cmd_reload=""
_cmd_stop=""
_pid_file=""

args_help=$(cat <<- EOF
$0 参数说明：
    --name 服务名称
    --start 服务启动指令
    --reload 服务重载指令
    --stop 服务停止指令
EOF
)
args_error=$(cat <<- EOF
$args_help
错误：
EOF
)
ARGS=`getopt -o h --long name:,start:,reload:,stop:,pid: -n "$args_error" -- "$@"`
if [ $? != 0 ]; then exit 1 ; fi
eval set -- "${ARGS}"
while true
do
    case "$1" in
        -h)
            echo $args_help ;
            exit 0 ;;
        --name)
            _service="$2" ;
            shift 2 ;;
        --start)
            _cmd_start="$2" ;
            shift 2 ;;
        --reload)
            _cmd_reload="$2" ;
            shift 2 ;;
        --stop)
            _cmd_stop="$2" ;
            shift 2 ;;
        --pid)
            _pid_file="$2" ;
            shift 2 ;;
        --) shift; break ;;
        *)
            echo "参数读取错误" ; exit 1 ;;
    esac
done

_errors=""
[[ "$_service" == "" ]] && _errors="$_errors\n\t--name 缺少服务名称"
[[ "$_cmd_start" == "" ]] && _errors="$_errors\n\t--start 缺少服务启动指令"
[[ "$_cmd_stop" == "" ]] && _errors="$_errors\n\t--stop 缺少服务停止指令"
[[ ! "$_errors" == "" ]] && echo -e "缺少参数：$_errors" && exit 1

if [[ "$_pid_file" == "" ]]; then
    _pid_file="/var/run/${_service}.pid"
    _cmd_start="${_cmd_start} && /usr/bin/echo \$! > ${_pid_file}"
fi

exec_info=$(cat <<- EOF
ExecStart=$_cmd_start
ExecStop=$_cmd_stop
EOF
)
if [[ ! "$_cmd_reload" == "" ]]; then
exec_info=$(cat <<- EOF
$exec_info
ExecReload=$_cmd_reload
EOF
)
fi

cat << EOF > "/lib/systemd/system/$_service.service"
[Unit]
Description=Service to manage $_service
After=network.target

[Service]
Type=forking
LimitNOFILE=104800
Restart=always
RestartSec=30
PIDFile=${_pid_file}
${exec_info}
KillSignal=SIGQUIT
TimeoutStopSec=30
KillMode=control-group
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
chmod 755 /lib/systemd/system/$_service.service
systemctl daemon-reload

echo "Install service $_service completed."
echo "Manage service $_service with：systemctl start|stop|reload|restart $_service"
