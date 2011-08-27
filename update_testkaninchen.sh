#!/bin/sh


IPS="192.168.0.252"
#IPS="104.0.200.42"
#IPS="$IPS 104.0.200.65 104.0.200.66 104.0.200.67 104.0.200.42 104.0.200.2 104.0.200.6 104.0.200.49"
#IPS="$IPS 104.0.200.255"

cd ~/yaffmap-agent/files
tar --exclude=".svn" --exclude="*~"  -czf ../uci_redist.tar.gz etc/init.d/yaffmap lib/yaffmap/common* lib/yaffmap/uci* lib/yaffmap/release.txt

for ip in  $IPS
do
	if [ "$1" = "trigger" ]
	then
		echo "trigering \"$2 $3 $4\" on node $ip"
		ssh  root@$ip "export PATH=/bin:/sbin:/usr/bin:/usr/sbin; /etc/init.d/yaffmap $2 $3 $4"
	else
		echo -n "updating $ip"
		echo -n " [SCP]"
		scp -q ../uci_redist.tar.gz root@$ip:/tmp/ 
		echo " [unpacking]"
		ssh root@$ip "export PATH=/bin:/sbin:/usr/bin:/usr/sbin; rm -rf /lib/yaffmap /etc/init.d/yaffmap;cd /; tar xzf /tmp/uci_redist.tar.gz; rm /tmp/uci_redist.tar.gz; /etc/init.d/yaffmap start -du -v"
	fi
done

rm ../uci_redist.tar.gz
