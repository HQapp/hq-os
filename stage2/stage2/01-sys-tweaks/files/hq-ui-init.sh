
#!/bin/bash


LOG_FILE="/var/log/hq-ui-install.log"


echo "HQapp - Initializing HQ UI Application " >> ${LOG_FILE}
sudo apt-get update
sudo apt-get upgrade -y


echo "HQapp - Enabling web server (Nginx) " >> ${LOG_FILE}
# Ensure nginx is installed
sudo apt-get install nginx


echo "HQapp - Enabling firewall " >> ${LOG_FILE}
# Enable nginx basic firewall
sudo apt-get install ufw
sudo ufw enable
# restart web server for good measure
systemctl restart nginx


echo "HQapp - Cloning project " >> ${LOG_FILE}
# This will be where our project sits. Will need this info for continous deployment
cd "${ROOTFS_DIR}/home/Documents"
# Need to verify that a github access token was given
if [ -z "${GITHUB_TOKEN}" ]
then
    echo "[ERR] HQapp - GITHUB_TOKEN was not found. Verify you are setting the config variables correctly." >> ${LOG_FILE}
else
    git clone "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/HQapp/hq-home-ui.git"
fi


echo "Initializing Umi " >> ${LOG_FILE}
# Ensure node/npm is installed
if ! [ -x "${command -v node}" ]; then
    echo "[WARN] HQapp - Node is not installed. Installing now " >> $LOG_FILE
    curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
    sudo apt-get install nodejs npm
fi
sudo npm i -g umi

echo "Building and deploying HQ's UI" >> ${LOG_FILE}
# Build the application and copy its contents to /www/html so we can
# enable wormhole tunneling from Dataplicity (remote connection)
# to the application, which is on port 80
umi build
cp -a ~/hq-home-ui/dist/. /var/www/html/

echo "Restarting web server to finish deployment..." >> ${LOG_FILE}
systemctl restart nginx

echo "HQapp - Initialization complete" >> ${LOG_FILE}

rm /boot/rpi_init

source /etc/rc.local
exit 0






