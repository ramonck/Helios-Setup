#!/bin/bash
# Author: Ramon Lima
# 
# Date 07/20/2014
# -------------------------------------------------
# Your Changes Start Here
# Authentication Section Username/Password/Key of Server
# User name @_ruser
 _ruser="root"
# If you're using user with password @_rpass authentication (sshpass will be installed)
 _rpass=""
# If you use private key for authentication (your_key.pem), if not leave it blank
 _rkey="./your-key.pem"
 
# Server Section
# Change to the DNS/IP of your server @_rserver
 _rserver="your-ip"
# Your Changes End Here
# -------------------------------------------------


# -------------------------------------------------
# Script Logic Start
# No @_rkey and with @_rpass criteria
if [[ -z $_rkey &&  -n $_rpass ]]; then 
 sudo apt-get -qy install sshpass
 _conn="sshpass -p ${_rpass} ssh ${_ruser}@${_rserver}"
# No @_rkey and no @_rpass criteria
elif [[ -z $_rkey && -z $_rpass ]]; then 
_conn="ssh ${_ruser}@${_rserver}" 
# With @_rkey authentication
elif [[ -n $_rkey ]]; then 
_conn="ssh -i ${_rkey} ${_ruser}@${_rserver}" 
fi
nc ${_rserver} 22 < /dev/null
if [[ $? == 1 ]]; then
echo "ERROR: Unable to connect to server, please verify and configure your server."
else
echo ">> Connection is available with this server"
# Get public IP address
echo ">> Getting public address"
_serverip=$(${_conn} "curl ifconfig.me")

# Old hostname
echo ">> Getting current hostname"
_oldhostn=$(${_conn} "cat /etc/hostname")

#Ask for new hostname $newhost
while [[ -z ${_newhostn} ]]; do
echo "Enter new hostname: (Default:${_serverip}, Old[Current]:${_oldhostn})"
read _newhostn
if [[ -z ${_newhostn} ]]; then
_newhostn=${_serverip}
fi
done
echo "chosen DNS ${_newhostn}"
_cmd1="touch tmphost && echo ${_newhostn} > tmphost && sudo cp tmphost /etc/hostname && rm tmphost"
_cmd2="sudo service hostname restart"

echo ">> Renaming Hostname"
${_conn} "$_cmd1"
${_conn} "$_cmd2"

# Update Apt Records
echo ">> Updating Apt Records"
${_conn} "sudo apt-get -qy update > /dev/null"
# Install JDK (Java)
echo ">> Installing Java"
${_conn} "sudo apt-get -qy install default-jdk > /dev/null"
# Install ZooKeeper
echo ">> Installing ZooKeeper"
${_conn} "sudo apt-get -qy install zookeeper > /dev/null"
# Download the packages
echo ">> Downloading Helios Packages"
${_conn} "wget https://github.com/spotify/helios/releases/download/0.0.31/helios-agent_0.0.31_all.deb"
${_conn} "wget https://github.com/spotify/helios/releases/download/0.0.31/helios-master_0.0.31_all.deb"
${_conn} "wget https://github.com/spotify/helios/releases/download/0.0.31/helios-services_0.0.31_all.deb"
${_conn} "wget https://github.com/spotify/helios/releases/download/0.0.31/helios_0.0.31_all.deb"
# Install the packages
echo ">> Installing Helios Packages"
${_conn} "sudo dpkg -i helios*"
# Start ZooKeeper
echo ">> Starting ZooKeeper in foreground"
${_conn} "/usr/share/zookeeper/bin/zkServer.sh start-foreground &"
# Start Helios Master
#echo ">> Starting Helios-Master in foreground"
#${_conn} "helios-master &"
fi
exit 0
# Script Logic End
# -------------------------------------------------
