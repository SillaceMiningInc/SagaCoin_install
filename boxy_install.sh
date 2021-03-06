#!/bin/bash
#paranoidtruth

echo "=================================================================="
echo "PARANOID TRUTH BOXY MN Install"
echo "=================================================================="
echo "Installing, this will compile and take up to 30 min to run..."
read -p 'Enter your masternode genkey you created in windows, then hit [ENTER]: ' GENKEY

echo -n "Installing pwgen..."
sudo apt-get install pwgen -y 

echo -n "Installing dns utils..."
sudo apt-get install dnsutils -y

PASSWORD=$(pwgen -s 64 1)
WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)

echo -n "Installing with GENKEY: $GENKEY, RPC PASS: $PASSWORD, VPS IP: $WANIP..."

#begin optional swap section
echo "Setting up disk swap..."
free -h 
sudo fallocate -l 4G /swapfile 
ls -lh /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab sudo bash -c "
echo 'vm.swappiness = 10' >> /etc/sysctl.conf"
free -h
echo "SWAP setup complete..."
#end optional swap section

echo "Installing packages and updates..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install -y software-properties-common python-software-properties
sudo add-apt-repository -y ppa:bitcoin/bitcoin
sudo apt-get install build-essential libssl-dev libdb++-dev libboost-all-dev libqrencode-dev -y
sudo apt-get install build-essential libssl-dev libcrypto++-dev libminiupnpc-dev libgmp-dev libgmp3-dev -y
sudo apt-get install autoconf autogen automake libtool -y
sudo apt-get install git -y
sudo apt-get install pkg-config -y
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y

#do the bitcoin core stuff:
echo "BITCOIN CORE..."
cd ~/
git clone https://github.com/bitcoin-core/secp256k1.git
cd secp256k1
./autogen.sh
./configure
make
./tests
sudo make install

echo "DOWNLOADING BOXY BLOCKS BOOTSTRAP"
cd ~/
wget https://raw.githubusercontent.com/paranoidtruth/SagaCoin_install/master/boxy_blocks.sh
sudo chmod +x boxy_blocks.sh

#back to BOXY
echo "MAKING BOXY..."
cd ~/
git clone https://github.com/boxycoin/boxycoin.git
cd boxycoin
sudo chown 755 autogen.sh
sudo ./autogen.sh
#making sure 4.8 loaded correctly!  weird, some have crashed here
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
sudo ./configure
sudo make

echo "COPY TO LOCAL..."
sudo cp ~/boxycoin/src/boxycoind /usr/local/bin
sudo cp ~/boxycoin/src/boxycoin-cli /usr/local/bin

echo "INITIAL START: IGNORE ANY CONFIG ERROR MSGs..." 
boxycoind -daemon

echo "Loading wallet, be patient, wait 60 seconds ..." 
sleep 60
boxycoin-cli getmininginfo
boxycoin-cli stop

echo "creating config..." 

cat <<EOF > ~/.boxycoin/boxycoin.conf
rpcuser=rpcboxycoin
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
rpcport=21523
listen=1
server=1
daemon=1
maxconnections=64
listenonion=0
port=21524
masternode=1
masternodeaddr=$WANIP:21524
masternodeprivkey=$GENKEY
addnode=45.76.84.233:21524
addnode=65.29.64.42:21524
addnode=91.90.188.110:21524
addnode=207.246.72.49:21524
EOF

echo "setting basic security..."
sudo apt-get install fail2ban -y
sudo apt-get install -y ufw
sudo apt-get update -y

#add a firewall & fail2ban
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw allow 21524/tcp 
sudo ufw logging on
sudo ufw status
sudo ufw enable

#fail2ban:
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
echo "basic security completed..."

echo "restarting wallet, be patient, wait..."
boxycoind -daemon
sleep 60

echo "boxycoin-cli getmininginfo:"
boxycoin-cli getmininginfo

echo "Note: installed with IP: $WANIP and genkey: $GENKEY.  If either are incorrect, you will need to edit the .boxycoin/boxycoin.conf file"
echo "Done!  It may take time to sync, you can start your final setup checks in the guide once the block count is sync'd"

echo "STARTING BOXY BLOCKS BOOTSTRAP..."
sleep 30

cd ~/
sh boxy_blocks.sh

echo "#########################################################################"
echo "# CHECK STATUS, GET MN REWARD & NODE STATUS ALERTS: https://mnode.club  #"
echo "#########################################################################"
