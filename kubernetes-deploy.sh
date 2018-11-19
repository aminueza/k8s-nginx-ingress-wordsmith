#!/bin/bash

set -x

usage()
{
    cat <<END
Kubernetes-deply.sh: deploys K8s-wordsmith application to Kubernetes cluster
Parameters:
  -i | --install 
    Install docker and Kubernetes
  -c | --configure 
    Configure kubernetes cluster and network
  --helm
    Install Helming
  -r | --reset 
    Reset Cluster
  -h | --help
    Displays this help text and exits the script
Script to deploy k8s-wordsmith application with kubernetes, NGINX Ingress, WAF modsecurity + OWASP and Let's Encrypt
END
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i | --install )
        install_services="yes"; shift;;
    -c | --configure )
        configure_kube="yes"; shift;;
    -r | --reset )
        reset_kube="yes"; shift;;   
    --helm )
        install_helm='yes'; shift;;
    -h | --help )
        usage; exit 1 ;;
    *)
        echo "Unknown option $1"
        usage; exit 2 ;;
  esac
done

if [[ $install_services ]]; then
    echo "#################### Installing mandatory services ####################"
    echo ''
    apt-get update && apt-get upgrade -y && apt-get install -y apt-transport-https docker.io apache2-utils docker-compose
    systemctl enable docker.service
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
    deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
    apt-get update && apt-get install -y kubelet kubeadm kubectl
fi

if [[ $reset_kube ]]; then
    echo "#################### Reset Kubernetes ####################"
    echo ''
    kubeadm reset || printf ''
    docker rmi -f $(docker images -q)
    rm -rf ../.kube/*
fi

if [[ $configure_kube ]]; then
    echo "#################### Configuring Kubernetes Cluster and Network ####################"
    echo ''
    kubeadm init --pod-network-cidr=192.168.0.0/16 
    kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
    kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
    kubectl --kubeconfig=/etc/kubernetes/admin.conf taint nodes --all node-role.kubernetes.io/master-kubectl taint nodes --all node-role.kubernetes.io/master-
    mkdir -p $HOME/.kube && cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && chown $(id -u):$(id -g) $HOME/.kube/config && export KUBECONFIG=/etc/kubernetes/admin.conf
    kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
fi

if [[ $helm ]]; then
    echo "#################### Installing Helm ####################"
    echo ''
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
    chmod +x get_helm.sh && sh get_helm.sh && rm get_helm.sh
    helm init
fi 

echo "#################### Cleaning up old deployment ####################"
echo ''
kubectl create -f custom-namespace.yaml --namespace=custom-namespace
kubectl delete namespaces custom-namespace

echo "#################### Deploying infrastructure components ####################"
echo ''
kubectl apply -f 01-nginx-ingress-waf/07-secret-auth-basic.yaml
kubectl apply -f 01-nginx-ingress-waf/01-ingress-namespace.yaml
kubectl apply -f 01-nginx-ingress-waf/02-ingress-roles.yaml
kubectl apply -f 01-nginx-ingress-waf/03-ingress-config.yaml
kubectl apply -f 01-nginx-ingress-waf/04-ingress-default-backend.yaml
kubectl apply -f 01-nginx-ingress-waf/05-ingress-deployment.yaml
kubectl apply -f 01-nginx-ingress-waf/05-ingress-deployment.yaml

echo "#################### Deploying wordsmith application ####################"
echo ''
kubectl apply -f 02-wordsmith-app/01-namespace.yaml
cd 02-wordsmith-app && docker-compose build && cd ../
kubectl apply -f 02-wordsmith-app/02-kube-deployment.yml
kubectl apply -f 02-wordsmith-app/03-ingress-wordsmith.yaml

echo "k8s-wordsmith deployment is DONE"