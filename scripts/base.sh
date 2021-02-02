#!/bin/bash
while [ ! -f /root/instnum.txt ]; do
    sleep 1
done
curl -d "Instance=$(< instnum.txt)&Log=Booting VSI" -X POST https://daidemos.com/log
mkdir /root/demo
mkdir /root/da
export DEBIAN_FRONTEND=noninteractive
export HOME=/root
export USER=root
apt-get update
curl -d "Instance=$(< /root/instnum.txt)&Log=Patching VSI" -X https://daidemos.com/log
apt-get -y -o Dpkg::Options::="--force-confnew" upgrade
curl -d "i=$(< /root/instnum.txt)&Log=Installing Core Packages" -X POST https://daidemos.com/log
apt-get -y -o Dpkg::Options::="--force-confnew" install libcurl4 libssl1.1 build-essential fdupes
curl -d "Instance=$(< /root/instnum.txt)&Log=Installing Node" -X POST https://daidemos.com/log
wget https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered
bash update-nodejs-and-nodered --confirm-root --confirm-install --skip-pi
npm install --prefix /root/.node-red node-red-node-watson
npm install --prefix /root/.node-red node-red-contrib-startup-trigger
wget -O /root/.node-red/flows_$(< /root/companysafe.txt)-vsi.json https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/demos/watson/flows.json
curl -d "Instance=$(< /root/instnum.txt)&Log=Starting Data Aggregator" -X POST https://daidemos.com/log
apt-get install -y -o Dpkg::Options::="--force-confnew" libgbm-dev libpangocairo-1.0-0 libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6 libnss3 libcups2 libxss1 libxrandr2 libgconf2-4 libasound2 libatk1.0-0 libgtk-3-0
wget -O /root/companylogo.png https://daidemos.com/$(< /root/company.txt).png
wget -O /root/companyurl.txt https://daidemos.com/$(< /root/company.txt).txt
wget -O /root/da/package.json https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/package.json
wget -O /root/da/data_aggregator.js https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/data_aggregator.js
wget -O /root/da/bg.js https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/bg.js
npm --prefix /root/da install /root/da
curl -d "Instance=$(< /root/instnum.txt)&Log=Starting Services" -X POST https://daidemos.com/log
systemctl enable nodered.service
systemctl start nodered.service
curl -d "Instance=$(< /root/instnum.txt)&Log=Provision complete! Content loading and model training will occur in the background over the next few hours." -X POST https://daidemos.com/log
curl -d "Instance=$(< /root/instnum.txt)" -X POST https://daidemos.com/complete
