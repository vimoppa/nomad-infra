#!/bin/bash

set -xe

######################################################
# Install dependenciess
######################################################

# Disable interactive apt prompts
export DEBIAN_FRONTEND=noninteractive

cd /tmp

function installDependencies() {
    echo "Installing dependencies..."
    sudo apt-get install -y software-properties-common 2>/dev/null
    sudo apt-get update 2>/dev/null
    sudo apt-get install -y unzip vim tree jq curl tmux 2>/dev/null
}

function installDocker() {
    echo "Installing Docker..."
    sudo apt-get update
    echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections
    sudo apt-get remove docker docker-engine docker.io 2>/dev/null
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) \
      stable"
    sudo apt-key fingerprint 0EBFCD88
    sudo apt-get update
    sudo apt-get install -y docker-ce
    sudo usermod -aG docker ubuntu
    sudo service docker restart
    sudo usermod -aG docker ubuntu
    sudo docker --version
}

function installJava() {
    echo "Installing Java..."
    sudo add-apt-repository -y ppa:openjdk-r/ppa
    sudo apt-get update
    sudo apt-get install -y openjdk-8-jdk
    export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
}

function installSSL() {
    for bin in cfssl cfssl-certinfo cfssljson; do
        echo "Installing $bin..."
        curl -sSL https://pkg.cfssl.org/R1.2/${bin}_linux-amd64 >./${bin}
        sudo install ./${bin} /usr/local/bin/${bin}
    done
}

function installNomad() {
    nomad_download=https://releases.hashicorp.com/nomad/${nomad_version}/nomad_${nomad_version}_linux_amd64.zip
    nomad_bin_dir=/usr/local/bin/nomad

    echo "Fetching Nomad..."
    curl -sLo nomad.zip ${nomad_download}

    echo "Installing Nomad..."
    unzip nomad.zip 2>/dev/null
    sudo chmod +x nomad
    sudo chown root:root nomad
    sudo install nomad ${nomad_bin_dir}
    nomad -autocomplete-install
}

function installConsul() {
    consul_download=https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip
    consul_bin_dir=/usr/local/bin/consul

    echo "Fetching Consul..."
    curl -sLo consul.zip ${consul_download}

    echo "Installing Consul..."
    unzip consul.zip 2>/dev/null
    sudo chmod +x consul
    sudo chown root:root consul
    sudo mv consul ${consul_bin_dir}
}

function installConsulTemplate() {
    consul_template_download=https://releases.hashicorp.com/consul-template/${consul_template_version}/consul-template_${consul_template_version}_linux_amd64.zip
    consul_template_bin_dir=/usr/local/bin/consul-template

    echo "Fetching Consul Template..."
    curl -sLo consul-template.zip ${consul_template_download}

    echo "Installing Consul Template..."
    unzip consul-template.zip 2>/dev/null
    sudo chmod +x consul-template
    sudo chown root:root consul-template
    sudo mv consul-template ${consul_template_bin_dir}
}

function installVault() {
    vault_download=https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip
    vault_bin_dir=/usr/local/bin/vault

    echo "Fetching Vault..."
    curl -sLo vault.zip ${vault_download}

    echo "Installing Vault..."
    unzip vault.zip 2>/dev/null
    sudo chmod +x vault
    sudo chown root:root vault
    sudo mv vault ${vault_bin_dir}
}

function installFabio() {
    fabio_download=https://github.com/fabiolb/fabio/releases/download/v${fabio_version}/fabio-${fabio_version}-go1.15-linux_amd64
}

# Install software
installDependencies

# Disable the firewall
sudo ufw disable || echo "ufw not installed"

# Install Docker
installDocker

# Install Java
installJava

# Install SSL packages
installSSL

# Install Consul
installConsul

# Install Consul Template
installConsulTemplate

# Install Fabio
# installFabio

# Install Vault
installVault

# Install Nomad
installNomad
