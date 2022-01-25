#!/bin/bash

set -eo pipefail

dir=$(dirname $0)

echo "apply coredns patch"

IP=""
if minikube status 2>&1 >/dev/null; then
	IP=$(minikube ip)
elif kind get clusters 2>&1 >/dev/null; then
	IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-control-plane)
fi


if [ -z $IP ]; then
	echo "cannot get controle plane node ip"
	exit 1
fi

echo "control-plane node ip: $IP"

temp_dir=`mktemp -d`

trap '{ rm -rf -- "$temp_dir"; }' EXIT
sed "s/minikube_ip/$IP/g" $dir/hosts > $temp_dir/local.dev.hosts
cp -r $dir/*.yaml $temp_dir/

pushd $temp_dir

while IFS= read -r line; do
    echo "    $line" >> coredns-patch.yaml
done < local.dev.hosts

kubectl patch configmap coredns -n kube-system --patch "$(cat coredns-patch.yaml)"
kubectl patch deployment coredns -n kube-system --patch "$(cat deployment-patch.yaml)"

popd
