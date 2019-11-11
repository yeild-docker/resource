
_HOME=/usr/local/letsencrypt

mkdir -p $_HOME
cd $_HOME

yum install -y crontabs vixie-cron wget git expect openssl openssl-devel python-devel python-tools python-virtualenv libffi-devel augeas-libs gcc redhat-rpm-config glibc glibc-common libgcc
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
yum install -y epel-release && yum install -y python-pip
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

wget https://dl.eff.org/certbot-auto -O certbot-auto && chown root certbot-auto && chmod 0755 certbot-auto && mv certbot-auto /usr/local/bin/certbot-auto
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

rm -rf auth && git clone https://github.com/yeild-web/certbot-letencrypt-wildcardcertificates-alydns-au.git auth && sed -i 's/^\(ALY_KEY="\).*\("\)$/\1LTAI4Ft38EVexsBP35NE7SVD\2/g' auth/au.sh && sed -i 's/^\(ALY_TOKEN="\).*\("\)$/\1XgKxJignZvIHxEJj5SSYiUKgTk0tJX\2/g' auth/au.sh
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

/usr/local/bin/certbot-auto certonly --email 935057137@qq.com -d *.yeild.top --manual --rsa-key-size 4096 --preferred-challenges dns --server https://acme-v02.api.letsencrypt.org/directory --manual-auth-hook ${_HOME}'/auth/au.sh python aly add' --manual-cleanup-hook ${_HOME}'/auth/au.sh python aly clean' --agree-tos --manual-public-ip-logging-ok --noninteractive --no-bootstrap
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

openssl x509 -in  /etc/letsencrypt/live/yeild.top/cert.pem -noout -text
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

/usr/local/bin/certbot-auto renew  --manual --preferred-challenges dns --manual-auth-hook ${_HOME}'/auth/au.sh python aly add' --manual-cleanup-hook ${_HOME}'/auth/au.sh python aly clean' --dry-run
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
echo "0 2 */2 * * root /usr/local/bin/certbot-auto renew --manual --preferred-challenges dns --manual-auth-hook '${_HOME}/auth/au.sh python aly add' --manual-cleanup-hook '${_HOME}/auth/au.sh python aly clean'" | tee -a /etc/crontab > /dev/null
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi

systemctl enable crond
cmd_rs=$?; if [ $cmd_rs -ne 0 ]; then exit $cmd_rs; fi
systemctl start crond

# wget git expect openssl-devel python-devel python-tools libffi-devel python-virtualenv
# yum history undo -y `yum history list git | awk 'NR==4{print $1}'`

exit 0
