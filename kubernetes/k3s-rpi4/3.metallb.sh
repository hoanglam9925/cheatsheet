#/bin/bash
#Install metallb to cluster
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.5/config/manifests/metallb-native.yaml

#Setup pools address (choose IP unused)
echo "apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250
" > pools.yaml

#Advertisement IP in pools to router
echo "apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
" > advert.yaml

#Delay waiting for metallb run
sleep 120
kubectl apply -f pools.yaml
kubectl apply -f advert.yaml