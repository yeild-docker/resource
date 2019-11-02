# run cluster with docker
docker
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then
	curl -fsSL "https://raw.githubusercontent.com/yeild-docker/resource/master/centos7/docker/init.sh" | sh -s -- -v 19.03.4
	cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
fi
docker network create gpcluster
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
docker run -tid --privileged=true --restart=always --network=gpcluster -p 5432:5432 --name gpmaster centos:7 /usr/sbin/init
docker run -tid --privileged=true --restart=always --network=gpcluster --name gpsdw1 centos:7 /usr/sbin/init
docker run -tid --privileged=true --restart=always --network=gpcluster --name gpsdw2 centos:7 /usr/sbin/init
docker run -tid --privileged=true --restart=always --network=gpcluster --name gpsdw3 centos:7 /usr/sbin/init

_GPVERSION=6.0.1
_GPPACK=greenplum-db-${_GPVERSION}.rpm
wget https://github.com/greenplum-db/gpdb/releases/download/${_GPVERSION}/greenplum-db-${_GPVERSION}-rhel7-x86_64.rpm -O ${_GPPACK}
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
docker cp ./${_GPPACK} gpmaster:/${_GPPACK} && docker cp ./init.sh gpmaster:/init.sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
docker cp ./${_GPPACK} gpsdw1:/${_GPPACK} && docker cp ./init.sh gpsdw1:/init.sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
docker cp ./${_GPPACK} gpsdw2:/${_GPPACK} && docker cp ./init.sh gpsdw2:/init.sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
docker cp ./${_GPPACK} gpsdw3:/${_GPPACK} && docker cp ./init.sh gpsdw3:/init.sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi


docker exec -it gpsdw1 /bin/sh /init.sh -f ${_GPPACK}
docker exec -it gpsdw2 /bin/sh /init.sh -f ${_GPPACK}
docker exec -it gpsdw3 /bin/sh /init.sh -f ${_GPPACK}
docker exec -it gpmaster /bin/sh /init.sh -m -f ${_GPPACK}

exit 0
