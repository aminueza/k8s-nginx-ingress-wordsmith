# Veriff Assessment

## Introduction

This is a [Kubernetes](https://kubernetes.io/) cluster setup running with [NGINX](https://www.nginx.com/) ingress and a Web Application Firewall (WAF) enabled.

## Technologies

- [Kubernetes](https://kubernetes.io/), for automating deployment, scaling, and management of containerized applications.
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/), for assemblying a NGINX configuration file (nginx.conf).
- [Ansible](https://www.ansible.com/), for agentless IT automation.
- [Let’s Encrypt Certificate](https://letsencrypt.org/), for free, automated, and open certificate.
- [cert-manager](https://github.com/jetstack/cert-manager) for automatically request certificates for Kubernetes Ingress resources from Let's Encrypt.
- [ModSecurity Web Application Firewall](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/third-party-addons/modsecurity.md), for application protection, HTTP traffic monitoring, logging and real-time analysis.

## Demo Application

To demonstrate the cluster functionalities, [Kubernetes Wordsmith Demo](https://github.com/dockersamples/k8s-wordsmith-demo) has been used. It runs across three containers, resulting in a random sentence generator.

## Infrastructure

- **Kubernetes**
  - **NGINX Ingress Controller**
    - **Container "db"**: a PostgreSQL database which stores words
    - **Container "words"**: a Java REST API which serves words read from the database
    - **Container "web"**: a Go web application which calls the API and builds words into sentences

## How to run

In your machine, run the script `Kubernetes-deploy.sh` and everything should be up and running.

## Tests

This structure was tested on a Ubuntu 18.04 machine.