#/bin/bash
#Setup proxy nginx
apt install nginx -y
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bk
echo "
load_module '/usr/lib/nginx/modules/ngx_stream_module.so';
worker_processes 4;
worker_rlimit_nofile 40000;
events {
	worker_connections 8192;
}
stream {
	upstream k3snodes {
		least_conn;
		server 192.168.1.26:6443 max_fails=3 fail_timeout=5s;
		server 192.168.1.30:6443 max_fails=3 fail_timeout=5s;
		server 192.168.1.102:6443 max_fails=3 fail_timeout=5s;
	}
	server {
		listen 6443;
		proxy_pass k3snodes;
	}
}
" > /etc/nginx/nginx.conf
systemctl restart nginx

#Install k3s and kubectl command at load balancer
curl -sLS https://get.k3sup.dev | sh -

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

#Install k3s cluster
k3sup install --host=pi30 --user=root --cluster --tls-san 192.168.1.172 --k3s-extra-args="--no-deploy servicelb --no-deploy traefik --node-taint node-role.kubernetes.io/master=true:NoSchedule"

k3sup join --host=pi26 --server-user=root --server-host=192.168.1.30 --user=root --server --k3s-extra-args="--no-deploy servicelb --no-deploy traefik --node-taint node-role.kubernetes.io/master=true:NoSchedule"
k3sup join --host=pi102 --server-user=root --server-host=192.168.1.30 --user=root --server --k3s-extra-args="--no-deploy servicelb --no-deploy traefik --node-taint node-role.kubernetes.io/master=true:NoSchedule"

k3sup join --host=pi183 --server-user=root --server-host=192.168.1.30 --user=root
k3sup join --host=pi173 --server-user=root --server-host=192.168.1.30 --user=root

#Change kubectl host at loadbalancer
mkdir ~/.kube
scp -o "StrictHostKeyChecking no" root@pi30:/etc/rancher/k3s/k3s.yaml ~/.kube/
mv ~/.kube/k3s.yaml ~/.kube/config
