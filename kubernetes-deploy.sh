#!/bin/bash

set -x

YELLOW=$(tput setaf 11)
RESET=$(tput sgr0)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)


help_(){
    cat <<END
Kubernetes-deply.sh: deploys K8s-wordsmith application to Kubernetes cluster
Steps:
1) Install mandatory packages
2) Configure Kubernetes cluster and network
3) Deploy NGINX Ingress
4) Deploy Wordsmith

The wordsmith is now acessible at http://206.189.170.172:30081 

Reset the cluster:
 1) Press option 6 
 2) Restart at step two
END
}

install_services(){
    echo "#################### Installing mandatory services ####################"
    echo ''
    apt-get update && apt-get upgrade -y && apt-get install -y apt-transport-https docker.io apache2-utils docker-compose
    systemctl enable docker.service
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
    deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
    apt-get update && apt-get install -y kubelet kubeadm kubectl
}

reset_kube(){
    echo "#################### Reset Kubernetes ####################"
    echo ''
    kubeadm reset || printf 'y'
    docker rmi -f $(docker images -q)
    rm -rf ../.kube/*
}

configure_kube(){
    echo "#################### Configuring Kubernetes Cluster and Network ####################"
    echo ''
    kubeadm init --pod-network-cidr=192.168.0.0/16 
    kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
    kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
    kubectl --kubeconfig=/etc/kubernetes/admin.conf taint nodes --all node-role.kubernetes.io/master-kubectl taint nodes --all node-role.kubernetes.io/master-
    mkdir -p $HOME/.kube && cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && chown $(id -u):$(id -g) $HOME/.kube/config && export KUBECONFIG=/etc/kubernetes/admin.conf
}

install_helm(){
    echo "#################### Installing Helm ####################"
    echo ''
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
    chmod +x get_helm.sh && sh get_helm.sh && rm get_helm.sh
    helm init
}

list_pod(){
    echo "#################### Listing pods ####################"
    echo ''
    kubectl get pods --all-namespaces
}

list_svc(){
    echo "#################### Listing services ####################"
    echo ''
    kubectl get svc --all-namespaces
}

deploy_wordsmith(){
    echo "#################### Deploying wordsmith application ####################"
    echo ''
    cd 02-wordsmith-app
    kubectl apply -f 01-namespace.yaml
    docker-compose build
    kubectl apply -f 02-kube-deployment.yml
    kubectl apply -f 03-ingress-wordsmith.yaml
    cd ../
    echo "k8s-wordsmith deployment is DONE"
    echo "The wordsmith is now acessible at http://206.189.170.172:30081"
}

deploy_nginx(){
    echo "#################### Deploying infrastructure components ####################"
    echo ''
    kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
    kubectl apply -f 01-nginx-ingress-waf/07-secret-auth-basic.yaml
    kubectl apply -f 01-nginx-ingress-waf/01-ingress-namespace.yaml
    kubectl apply -f 01-nginx-ingress-waf/02-ingress-roles.yaml
    kubectl apply -f 01-nginx-ingress-waf/03-ingress-config.yaml
    kubectl apply -f 01-nginx-ingress-waf/04-ingress-default-backend.yaml
    kubectl apply -f 01-nginx-ingress-waf/05-ingress-deployment.yaml
    kubectl apply -f 01-nginx-ingress-waf/06-ingress-service.yaml
}

menu_app(){
	echo "${GREEN}\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
	echo "Script to deploy k8s-wordsmith application with kubernetes,\n"
  echo "NGINX Ingress, WAF modsecurity + OWASP and Let's Encrypt\n"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
	echo "${GREEN}~~${RESET} ${YELLOW} 1) ${RESET}Install Mandatory Packages"
	echo "${GREEN}~~${RESET} ${YELLOW} 2) ${RESET}Install Helm"
	echo "${GREEN}~~${RESET} ${YELLOW} 3) ${RESET}Configure Cluster and Network"
	echo "${GREEN}~~${RESET} ${YELLOW} 4) ${RESET}Deploy NGINX Ingress"
	echo "${GREEN}~~${RESET} ${YELLOW} 5) ${RESET}Deploy Wordsmith"
	echo "${GREEN}~~${RESET} ${YELLOW} 6) ${RESET}Reset Kubernetes"
	echo "${GREEN}~~${RESET} ${YELLOW} 7) ${RESET}List Services"
  echo "${GREEN}~~${RESET} ${YELLOW} 8) ${RESET}List Pods"
  echo "${GREEN}~~${RESET} ${YELLOW} 9) ${RESET}Help"
	echo "${GREEN}~~${RESET} ${YELLOW} 0) ${RESET}Exit"
	echo "${GREEN}~~\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
	echo "${YELLOW}Select a menu option or${RED} 0 to exit: ${RESET}"
}

#Menu
opt=
until [ "$opt" = "0" ]; do
	menu_app
	read opt
	case $opt in
		1)
			install_services
      ;;
		2)
			install_helm
      ;;
		3)	
			configure_kube
			;;
		4) 
			deploy_nginx
      ;;
		5)    
			deploy_wordsmith
			;;
    6)
      reset_kube
      ;;
		7)
			list_svc
			;;
    8)
			list_pod
			;;
    7)
			help_
			;;
		0) 
			echo "${YELLOW}[INFO] Exiting...${RESET}"
			exit ;;
	esac
done
