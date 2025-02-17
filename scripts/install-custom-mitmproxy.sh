#!/usr/bin/env bash
set -e
sudo timedatectl set-timezone "Europe/Berlin"
sudo iptables -F
until ping -c 1 8.8.8.8; do
  echo "Internet down...sleeping for 5..."
  sleep 5
done
export DEBIAN_FRONTEND=noninteractive

until sudo apt-get update &&
  sudo apt-get install -y traceroute \
    net-tools \
    unzip zip \
    tasksel \
    ubuntu-gnome-desktop \
    git \
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


sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
sudo sysctl -w net.ipv4.ip_forward=1
sudo mitmproxy --mode regular --proxyauth user:pw

sudo iptables -F
sudo iptables -t nat -F
sudo iptables -F
sudo iptables -A OUTPUT -m owner --uid-owner root -j ACCEPT
sudo iptables -A OUTPUT -m owner --uid-owner proxy -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 80 -j REJECT
sudo iptables -A OUTPUT -p tcp --dport 443 -j REJECT
sudo systemctl set-default graphical.target
sudo systemctl isolate graphical.target
