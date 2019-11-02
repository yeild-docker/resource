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

wget https://github.com/greenplum-db/gpdb/releases/download/6.0.1/greenplum-db-6.0.1-rhel7-x86_64.rpm -O greenplum-db-6.0.1.rpm
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
docker cp ./greenplum-db-6.0.1.rpm gpmaster:/greenplum-db-6.0.1.rpm
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
docker cp ./greenplum-db-6.0.1.rpm gpsdw1:/greenplum-db-6.0.1.rpm
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
docker cp ./greenplum-db-6.0.1.rpm gpsdw2:/greenplum-db-6.0.1.rpm
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
docker cp ./greenplum-db-6.0.1.rpm gpsdw3:/greenplum-db-6.0.1.rpm
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi


docker exec -it gpmaster /bin/bash

exit 0
