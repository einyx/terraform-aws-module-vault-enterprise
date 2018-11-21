#!/usr/bin/env bash
set -e
export GOPATH=/usr/local/

export GOROOT=/usr/local/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
# Install packages
sudo yum update -y
sudo yum install -y install curl unzip git gcc
wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
tar -xzf go1.10.3.linux-amd64.tar.gz -C /usr/local/

go get -u github.com/cloudflare/cfssl/cmd/cfssl
go get -u github.com/cloudflare/cfssl/cmd/cfssljson


#mkdir ~/bin
#curl -s -L -o ~/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
#curl -s -L -o ~/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
#chmod +x ~/bin/{cfssl,cfssljson}
#export PATH=$PATH:~/bin
# Fix s3
yum remove -y awscli python-s3transfer
yum install -y python36 python34-pip cfssl
pip3 install awscli==1.15.19



# Download Vault into some temporary directory
curl -L "${vault_download_url}" > /tmp/vault.zip

# Unzip it
cd /tmp
sudo unzip vault.zip
sudo mv vault /usr/local/bin
sudo chmod 0755 /usr/local/bin/vault
sudo chown vault:vault /usr/local/bin/vault
sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault
sudo setcap cap_net_bind_service=+ep /usr/local/bin/vault

# Setup the systemd service
cat <<EOF >/etc/systemd/system/consul.service
[Unit]
Description=Consul Server
Requires=basic.target network-online.target
After=basic.target network-online.target

[Service]
User=vault
Group=vault
PrivateDevices=yes
PrivateTmp=yes
ProtectSystem=full
ProtectHome=read-only
SecureBits=keep-caps
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/consul agent -config-dir /etc/consul/
KillSignal=SIGINT
TimeoutStopSec=30s
Restart=on-failure
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/vault.service

[Unit]
User=vault
Group=vault
Description=Vault Server
Requires=basic.target network-online.target
After=basic.target network-online.target

[Service]
# No Need for us to mess with /dev
PrivateDevices=yes

# We get a private tmp directory
PrivateTmp=yes

# System dirctories mounte in read only
ProtectSystem=full

# Home mounte in read-only
ProtectHome=read-only

# Security #####
# Drops all elevated privileges by default when launching the process
SecureBits=keep-caps

# Allow the process to disable mlock
LimitMEMLOCK=infinity

# Turn off acquisition of new privileges system-wide

# To be able to bind port < 1024
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

# Start #####
ExecStart=/usr/local/bin/vault server -config=/etc/vault/
KillSignal=SIGINT
TimeoutStopSec=30s
Restart=on-failure
StartLimitInterval=60s
StartLimitBurst=3
[Install]
WantedBy=multi-user.target
EOF

# Download Consul into some temporary directory
curl -L "${consul_download_url}" > /tmp/consul.zip

# Unzip it
cd /tmp
sudo unzip consul.zip
sudo mv consul /usr/local/bin
sudo chmod 0755 /usr/local/bin/consul
sudo chown root:root /usr/local/bin/consul


# Setup the configuration
cat <<EOF >/tmp/consul-config
${consul_config}
EOF

# Get the Instance ID
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

# Set the Hostname
hostnamectl set-hostname "${ name_prefix }-$INSTANCE_ID"
systemctl restart rsyslog.service




# Check if the file is present in the bucket, otherwise generate the certs
count=$(aws s3 ls s3://${ vault_resources_bucket_name }/ssl/ca.key | wc -l)
if [ $count -gt 0 ]
then
  (>&2 echo "$path already exists!")
  return
else
    mkdir -p /tmp/ssl && cd /tmp/ssl

    # Write the default ca config file
    cfssl print-defaults csr > ca-csr.json 

    # RSA 2048 
    sed -i -e "s/ecdsa/rsa/g" ca-csr.json
    sed -i -e "s/256/2048/g" ca-csr.json
    sed -i -e "s/example/hcom-sandbox/g" ca-csr.json
 
    # Initialize the CA
    cfssl gencert -initca ca-csr.json | cfssljson -bare consul-ca
    
    # Write the cfssl config file, we want a long expiring time
    cat << EOF >/tmp/ssl/cfssl.json
{
  "signing": {
    "default": {
      "expiry": "87600h",
      "usages": [
        "signing",
        "key encipherment",
        "server auth",
        "client auth"
      ]
    }
  }
}
EOF

    # Generate a certificate for the Consul server
    echo '{"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=consul-ca.pem -ca-key=consul-ca-key.pem -config=cfssl.json \
    -hostname="server.global.consul,localhost,127.0.0.1" - | cfssljson -bare server

    # Generate a certificate for the Consul client
    echo '{"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=consul-ca.pem -ca-key=consul-ca-key.pem -config=cfssl.json \
    -hostname="client.global.consul,localhost,127.0.0.1" - | cfssljson -bare client

    # Generate a certificate for the CLI
    echo '{"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=consul-ca.pem -ca-key=consul-ca-key.pem -profile=client \
    - | cfssljson -bare cli

    # Move the generated cert from the tmp to the vault ssl directory
    mv ./* /etc/vault/ssl/

    # Sync the content of the ssl directory using encryption
    aws s3 sync /etc/vault/ssl s3://${ vault_resources_bucket_name }/ssl/ --delete --sse AES256
fi

# Get My IP Address
MYIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

# Write the vault config.hcl
cat <<EOF >/etc/vault/config.hcl
${vault_config}
EOF

# Write the consul config
mkdir -p {/etc/consul/,/opt/consul/data}
chown -R vault:vault /opt/consul

cat <<EOF >/etc/consul/config.hcl
${consul_config}
EOF

# Add My IP Address as cluster_address in Vault Configuration
sed -i -e "s/IP_ADDRESS/$MYIP/g" /etc/vault/config.hcl

# Add My IP Address as cluster_address in Vault Configuration
sed -i -e "s/IP_ADDRESS/$MYIP/g" /etc/consul/config.hcl
sed -i -e "s/REGION/${region}/g" /etc/consul/config.hcl

# Extra install steps (if any)
${vault_extra_install}

# Extra install steps (if any)
${consul_extra_install}

# Start Vault now and on boot
systemctl enable vault
systemctl start vault

# Start Consul now and on boot
systemctl enable consul
systemctl start consul

# License activation
sleep 600

curl \
    --request PUT \
    --data "${vault_license}" \
    http://127.0.0.1:8200/v1/sys/license

consul license put "${consul_license}"
