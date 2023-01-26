#!/bin/bash
#only configure once
[ -f /var/run/slurmctld.startup ] && exit 0

sed -e '/^hosts:/d' -i /etc/nsswitch.conf
echo 'hosts:      files myhostname' >> /etc/nsswitch.conf

while true
do
	sacctmgr show cluster &>/dev/null
	[ $? -eq 0 ] && break
	sleep 5
done

CLUSTERNAME="$(awk -F= '/^ClusterName=/ {print $2}' /etc/slurm/slurm.conf)"
[ -z "$CLUSTERNAME" ] && echo 'no cluster name' && exit 1
sacctmgr -vi add cluster "$CLUSTERNAME"
sacctmgr -vi add account bedrock Cluster="$CLUSTERNAME" Description="none" Organization="none"
sacctmgr -vi add user root Account=bedrock DefaultAccount=bedrock
sacctmgr -vi add user slurm Account=bedrock DefaultAccount=bedrock

for i in arnold bambam barney betty chip edna fred gazoo wilma dino pebbles
do
	sacctmgr -vi add user $i Account=bedrock DefaultAccount=bedrock
done

#disable admins to allow their setup in class
#sacctmgr -vi add user dino Account=bedrock DefaultAccount=bedrock admin=admin
#sacctmgr -vi add user pebbles Account=bedrock DefaultAccount=bedrock admin=admin

if [ "$(hostname -s)" = "mgmtnode" ]
then
	if [ ! -s /etc/slurm/nodes.conf ]
	then
		props="$(slurmd -C | head -1 | sed 's#NodeName=mgmtnode ##g')"
		echo "NodeName=DEFAULT $props Gres=gpu:gtx:3" >> /etc/slurm/nodes.conf

		cat /etc/nodelist | while read name ip4 ip6
		do
			[ ! -z "$ip6" ] && addr="$ip6" || addr="$ip4"
			echo "NodeName=$name NodeAddr=$addr" >> /etc/slurm/nodes.conf
		done
	fi
else
	while [ ! -s /etc/slurm/nodes.conf ]
	do
		sleep 0.25
	done
fi

touch /var/run/slurmctld.startup

exit 0
