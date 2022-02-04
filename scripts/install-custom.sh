#!/usr/bin/env bash

# make sure we can get the apt lock before running the plays
until sudo apt-get update; do echo "Waiting for apt-get lock"; sleep 5; done

## install apps
sudo snap install eclipse --classic
sudo snap install intellij-idea-community --classic
sudo snap install goland --classic
sudo apt install traceroute squid net-tools

## install java, gradle and maven
sdk i java
$JAVA_8=$(sdk list java|grep '8.0'|grep open|head -1|cut -d"|" -f6)
sdk i java $JAVA_8 < /dev/null
sdk i gradle < /dev/null
sdk i maven < /dev/null

## get repositories
git clone https://github.com/snyk/snyk-intellij-plugin
git clone https://github.com/snyk/snyk-eclipse-plugin
git clone https://github.com/snyk/vscode-extension

## configure firewall to only work through proxy
sudo systemctl enable squid
sudo systemctl restart squid
sudo iptables -A OUTPUT -m owner --uid-owner root -j ACCEPT
sudo iptables -A OUTPUT -m owner --uid-owner proxy -j ACCEPT
sudo iptables -A OUTPUT -p tcp -d snyk.io --dport 80,443 -j REJECT
