#!/usr/bin/env bash
set -e
sudo timedatectl set-timezone "Europe/Berlin"
sudo iptables -F
until ping -c 1 8.8.8.8; do
  echo "Internet down...sleeping for 5..."
  sleep 5
done
export DEBIAN_FRONTEND=noninteractive

#until sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo apt-get install -y traceroute squid net-tools unzip zip tasksel ubuntu-gnome-desktop git python3 iptables-persistent
until sudo apt-get update &&
  sudo apt-get install -y traceroute \
    sslsplit \
    net-tools \
    unzip zip \
    tasksel \
    ubuntu-gnome-desktop \
    git \
    squid \
    python3 ; do
  echo "Waiting for apt-get lock"
  sleep 5
done
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo apt-get autoremove -y && sudo apt-get clean -y

## install apps
sudo snap install intellij-idea-ultimate --classic
sudo snap install intellij-idea-community --classic
sudo snap install code --classic
sudo snap install code-insiders --classic
sudo snap install sublime-text --classic
sudo snap install node --classic
sudo snap install go --classic
sudo snap install chromium

## install java, gradle and maven
curl https://get.sdkman.io/ | bash
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
yes | sdk install java
# install JAVA 8
yes | sdk install java "$(sdk list java | grep " 8.0" | grep zulu | head -1 | cut -d"|" -f6 | xargs)"
yes | sdk install gradle
yes | sdk install maven

## get repositories
[[ ! -d "snyk-intellij-plugin" ]] && git clone https://github.com/snyk/snyk-intellij-plugin
[[ ! -d "snyk-intellij-plugin" ]] && git clone https://github.com/snyk/snyk-ls
[[ ! -d "snyk-eclipse-plugin" ]] && git clone https://github.com/snyk/snyk-eclipse-plugin
[[ ! -d "vscode-extension" ]] && git clone https://github.com/snyk/vscode-extension
[[ ! -d "vscode-extension" ]] && git clone https://github.com/snyk/snyk-visual-studio-plugin
[[ ! -d "vscode-extension" ]] && git clone https://github.com/snyk/snyk-eclipse-plugin

## configure firewall to only work through proxy

openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 1826 -key ca.key -out ca.crt -subj "/C=de/O=fake/OU=fakeorgunit/CN=fake.com"
sudo mkdir -p /tmp/sslsplit
sudo nohup sslsplit -D -l connections.log -j /tmp/sslsplit/ -k ca.key -c ca.crt ssl 0.0.0.0 8443 tcp 0.0.0.0 8080 &

sudo systemctl enable squid
sudo systemctl restart squid
sudo sysctl -w net.ipv4.ip_forward=1

sudo iptables -F
sudo iptables -t nat -F
sudo iptables -F
sudo iptables -t nat -A OUTPUT -p tcp -m owner --uid-owner vagrant --dport 80 -j REDIRECT --to-ports 8080
sudo iptables -t nat -A OUTPUT -p tcp -m owner --uid-owner vagrant --dport 443 -j REDIRECT --to-ports 8443
sudo iptables -t nat -A OUTPUT -p tcp -m owner --uid-owner proxy --dport 80 -j REDIRECT --to-ports 8080
sudo iptables -t nat -A OUTPUT -p tcp -m owner --uid-owner proxy --dport 443 -j REDIRECT --to-ports 8443
sudo systemctl set-default graphical.target
sudo systemctl isolate graphical.target
