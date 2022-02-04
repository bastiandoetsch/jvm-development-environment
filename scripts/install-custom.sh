#!/usr/bin/env bash
set -e
# make sure we can get the apt lock before running the plays
until ping -c 1 8.8.8.8; do echo "Internet down...sleeping for 5..."; sleep 5; done
until sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install -y traceroute squid net-tools
  do echo "Waiting for apt-get lock"
    sleep 5
  done

## install apps
sudo snap install eclipse --classic
sudo snap install intellij-idea-community --classic
sudo snap install goland --classic

## install java, gradle and maven
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
yes | sdk install java
# install JAVA 8
yes | sdk install java "$(sdk list java | grep 8.0 | grep zulu | head -1 | cut -d"|" -f6 | xargs)"
yes | sdk install gradle
yes | sdk install  maven

## get repositories
[[ ! -d "snyk-intellij-plugin" ]] && git clone https://github.com/snyk/snyk-intellij-plugin
[[ ! -d "snyk-intellij-plugin" ]] && git clone https://github.com/snyk/snyk-eclipse-plugin
[[ ! -d "snyk-intellij-plugin" ]] && git clone https://github.com/snyk/vscode-extension

## configure firewall to only work through proxy
sudo systemctl enable squid
sudo systemctl restart squid
sudo iptables -F
sudo iptables -A OUTPUT -m owner --uid-owner root -j ACCEPT
sudo iptables -A OUTPUT -m owner --uid-owner proxy -j ACCEPT
sudo iptables -A OUTPUT -p tcp -d snyk.io --dport 80 -j REJECT
sudo iptables -A OUTPUT -p tcp -d snyk.io --dport 443 -j REJECT
