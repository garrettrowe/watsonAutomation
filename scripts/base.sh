#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export HOME=/root
export USER=root
while [ ! -f /root/instnum.txt ]; do
    sleep 1
done
while [ ! -f /root/companysafe.txt ]; do
    sleep 1
done
while [ ! -f /root/company.txt ]; do
    sleep 1
done
curl -d "Instance=$(< instnum.txt)&Log=Booting VSI" -X POST https://daidemos.com/log
mkdir /root/demo
mkdir /root/da
wget -O /root/companylogo.png https://daidemos.com/$(< /root/company.txt).png
wget -O /root/companyurl.txt https://daidemos.com/$(< /root/company.txt).txt

apt-get update
curl -d "Instance=$(< /root/instnum.txt)&Log=Patching VSI" -X https://daidemos.com/log
apt-get -y -o Dpkg::Options::="--force-confnew" upgrade
curl -d "i=$(< /root/instnum.txt)&Log=Installing Core Packages" -X POST https://daidemos.com/log
apt-get -y -o Dpkg::Options::="--force-confnew" install libcurl4 libssl1.1 build-essential fdupes libgbm-dev libpangocairo-1.0-0 libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6 libnss3 libcups2 libxss1 libxrandr2 libgconf2-4 libasound2 libatk1.0-0 libgtk-3-0

curl -d "Instance=$(< /root/instnum.txt)&Log=Starting Data Aggregator" -X POST https://daidemos.com/log
wget -O /root/da/package.json https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/package.json
wget -O /root/da/data_aggregator.js https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/data_aggregator.js
wget -O /root/da/bg.js https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/bg.js
npm --prefix /root/da install /root/da
node /root/da/bg.js "$(< /root/companyurl.txt)" &
node /root/da/data_aggregator.js "$(< /root/companyurl.txt)" &

curl -d "Instance=$(< /root/instnum.txt)&Log=Installing Node" -X POST https://daidemos.com/log
wget https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered
bash update-nodejs-and-nodered --confirm-root --confirm-install --skip-pi
npm install --prefix /root/.node-red node-red-node-watson
npm install --prefix /root/.node-red node-red-contrib-startup-trigger



