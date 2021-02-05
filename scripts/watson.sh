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
while [ ! -f /root/industry.txt ]; do
    sleep 1
done
while [ ! -f /root/demo.txt ]; do
    sleep 1
done

curl -d "Instance=$(< /root/instnum.txt)&Log=Localizing: $(< /root/industry.txt)/$(< /root/demo.txt) " -X POST https://daidemos.com/log
wget -O /root/.node-red/flows_$(< /root/companysafe.txt)-vsi.json https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/demos/watson/flows.json
wget -O /root/assistant.json https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/demos/watson/assistant_$(< /root/industry.txt).json
sed -i 's/948376593648263452/$(/sbin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)/g' /root/assistant.json

curl -d "Instance=$(< /root/instnum.txt)&Log=Starting Services" -X POST https://daidemos.com/log
systemctl enable nodered.service
systemctl start nodered.service
