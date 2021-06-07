#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export HOME=/root
export USER=root
while [ ! -f /root/instnum.txt ]; do
    sleep 1
done
while [ ! -f /root/resourceGroup.txt ]; do
    sleep 1
done
while [ ! -f /root/companytitle.txt ]; do
    sleep 1
done
while [ ! -f /root/industry.txt ]; do
    sleep 1
done
while [ ! -f /root/demo.txt ]; do
    sleep 1
done
while [ ! -f /root/watsondiscoveryInst.txt ]; do
    sleep 1
done

curl -d "Instance=$(< /root/instnum.txt)&Log=Localizing: $(< /root/industry.txt)/$(< /root/demo.txt) " -X POST https://daidemos.com/log

dvar=`cat watsondiscoveryInst.txt | grep -c '{"discovery.version":"2'`
if [ $dvar -gt 0 ]
then
wget -O /root/.node-red/flows_$(< /root/resourceGroup.txt)-vsi.json https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/demos/watson/flowsV2.json
wget -O /root/discovery.tgz https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/demos/watson/discoV2.tgz
else
wget -O /root/.node-red/flows_$(< /root/resourceGroup.txt)-vsi.json https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/demos/watson/flows.json
wget -O /root/discovery.tgz https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/demos/watson/discovery.tgz
fi

wget -O /root/upsell.zip https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/demos/watson/upsell.zip
tar -xvzf /root/discovery.tgz -C /root
npm --prefix /root/discoveryService install /root/discoveryService

curl -d "Instance=$(< /root/instnum.txt)&Log=Starting Services" -X POST https://daidemos.com/log
systemctl enable nodered.service
systemctl start nodered.service
