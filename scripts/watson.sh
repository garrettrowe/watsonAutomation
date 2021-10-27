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
wget -O /root/secData.txt "https://daidemos.com/secData?company=$(< /root/companytitle.txt)"

dvar=`cat /root/secData.txt | grep -c 'none'`
if [ $dvar -gt 0 ]
then
wget -O /root/10k.tgz https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/demos/watson/10k.tgz
tar -xvzf /root/10k.tgz -C /root
else
mkdir /root/10k
wget -O /root/da/sec.js https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/sec.js
(node /root/da/sec.js "$(< /root/secData.txt)"  > /var/log/secData.log 2>&1 ) &
fi

wget -O /root/.node-red/flows_$(< /root/resourceGroup.txt)-vsi.json https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/demos/watson/flowsV2.json
wget -O /root/discovery.tgz https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/demos/watson/discoV2.tgz
wget -O /root/finance_dte_model.zip https://ibm.box.com/shared/static/h7sca2gyrz0az58vicqlqijh1mvtl71u.zip

wget -O /root/upsell.zip https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/demos/watson/upsell.zip
tar -xvzf /root/discovery.tgz -C /root
npm --prefix /root/discoveryService install /root/discoveryService

curl -d "Instance=$(< /root/instnum.txt)&Log=Starting Services" -X POST https://daidemos.com/log
systemctl enable nodered.service
systemctl start nodered.service
node /root/da/pmw.js "https://$(< /root/instnum.txt)-target.daidemos.com/" "$(< /root/companyurl.txt)" &
