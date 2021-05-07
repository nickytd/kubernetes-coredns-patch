#!/bin/bash

set -eo pipefail

dir=$(dirname $0)

echo "apply coredns patch"

IP=$(minikube ip)

if [ -z $IP ]; then
	echo "cannot get minikube ip"
	exit 1
fi

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
