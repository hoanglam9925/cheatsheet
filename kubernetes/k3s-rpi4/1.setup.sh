#/bin/bash
# Check ip address set static
IP=""
if [[ "$1" == 192.168.* ]];
then
	IP=$1
else
	echo "Invalid IP address. Enter rpi static IP address"
	exit 0
fi
CURRENT_IP=`hostname -I | awk '{print $1}'`
if [[ $CURRENT_IP != $IP ]]; then
	apt install nmap -y
	NMAP=`nmap -sn 192.168.1.0/24`
	if [[ "$NMAP" == *$1* ]]; then
		echo "IP address already in use. Take another"
		exit 0
	fi
fi
# Update, upgrade and setup ssh
apt update
apt upgrade -y

apt install vim -y
rm -rf /root/.ssh
mkdir /root/.ssh
echo "PUBLIC_KEY (Change your pubkey)" > /root/.ssh/authorized_keys

echo "PUBLIC_KEY (Change your pubkey)" > /root/.ssh/id_rsa.pub

echo "PRIVATE_KEY (Change your privkey)" > /root/.ssh/id_rsa

chmod 0400 /root/.ssh/*
# Add config to /boot/cmdline.txt
CMD="$(cat /boot/cmdline.txt)"
echo "$CMD cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1" > /boot/cmdline.txt

# Add config to /boot/config.txt
echo "arm_64bit=1" >> /boot/config.txt
# Setup iptables for k3s
iptables -F
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

echo "
interface wlan0
static ip_address=$IP/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1
" >> /etc/dhcpcd.conf
reboot