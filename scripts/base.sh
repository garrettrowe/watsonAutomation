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
while [ ! -f /root/companyurloverride.txt ]; do
    sleep 1
done
while [ ! -f /root/companycompact.txt ]; do
    sleep 1
done
curl -d "Instance=$(< /root/instnum.txt)&Log=Booting VSI" -X POST https://daidemos.com/log
mkdir /root/demo
mkdir /root/da
wget -O /root/logosmall.png https://daidemos.com/$(< /root/companycompact.txt).small.png
wget -O /root/logo.png https://daidemos.com/$(< /root/companycompact.txt).png
wget -O /root/ip.txt icanhazip.com

apt-get update
curl -d "Instance=$(< /root/instnum.txt)&Log=Patching VSI" -X POST https://daidemos.com/log
apt-get -y -o Dpkg::Options::="--force-confnew" upgrade
curl -d "i=$(< /root/instnum.txt)&Log=Installing Core Packages" -X POST https://daidemos.com/log
apt-get -y -o Dpkg::Options::="--force-confnew" install libcurl4 libssl1.1 build-essential fdupes libgbm-dev libpangocairo-1.0-0 libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6 libnss3 libcups2 libxss1 libxrandr2 libgconf2-4 libasound2 libatk1.0-0 libgtk-3-0 postgresql postgresql-contrib

curl -d "Instance=$(< /root/instnum.txt)&Log=Installing postgreSQL" -X POST https://daidemos.com/log
sed -i 's/\#listen_addresses/listen_addresses/g' /etc/postgresql/10/main/postgresql.conf
sed -i 's/localhost/\*/g' /etc/postgresql/10/main/postgresql.conf
sed -i 's/5432/16002/g' /etc/postgresql/10/main/postgresql.conf
sed -i 's/\# TYPE/host  all  all 0.0.0.0\/0 md5\# TYPE/g' /etc/postgresql/10/main/pg_hba.conf 
service postgresql restart
sudo -u postgres -H -- psql -c 'CREATE TABLE "SENTIMENT" ("USER" varchar (15), "ETIME" timestamp, "SCORE" decimal (8) ); CREATE TABLE "CALL_CLASSIFICATION" ("USER" varchar (15), "CLASS_NAME" varchar (255), "CONFIDENCE" decimal (16) ); CREATE TABLE "CALL_CLASSIFICATION_FINE" ("USER" varchar (15), "CLASS_NAME" varchar (255), "CONFIDENCE" decimal (16) ); CREATE TABLE "CALL_TONE" ("USER" varchar (15), "TONE_NAME" varchar (255), "SCORE" decimal (16) ); CREATE TABLE "CALL_RISK" ("USER" varchar (15), "RISK" decimal (8) ); CREATE TABLE "USERS" ("ID" varchar (11), "GENDER" varchar (1), "AGE" smallint, "MAIDEN_NAME" varchar (255), "LNAME" varchar (255), "FNAME" varchar (255), "ADDRESS" varchar (255), "CITY" varchar (255),"STATE" varchar (255), "ZIP" integer, "COUNTRY" varchar (255), "PHONE" bigint, "EMAIL" varchar (255), "CC_NUMBER" varchar (19), "MONTHLY_PAYMENT" smallint, "TOTAL_PAYMENTS" smallint, "LATITUDE" decimal (16), "LONGITUDE" decimal (16) ); CREATE TABLE "WIDGET_DATA" ("USER" varchar (15), "WIDGET_TYPE" varchar (50), "DATA_VALUE" varchar (10000), "DATA_ORDER" integer); CREATE VIEW "CALL_CLASSIFICATION_AVG_VW" AS SELECT "USER", "CLASS_NAME", sum("CONFIDENCE") as "CONFIDENCE" FROM "CALL_CLASSIFICATION" group by "USER", "CLASS_NAME" LIMIT 5;CREATE VIEW "CALL_CLASSIFICATIONFG" AS SELECT "USER", "CLASS_NAME", sum("CONFIDENCE") as "CONFIDENCE" FROM "CALL_CLASSIFICATION_FINE" group by "USER", "CLASS_NAME" LIMIT 5;'
sudo -u postgres -H -- psql -c "ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'md5909938b1443eb2d22ecfb40fa5a37199';"

curl -d "Instance=$(< /root/instnum.txt)&Log=Installing Node" -X POST https://daidemos.com/log
wget https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered
bash update-nodejs-and-nodered --confirm-root --confirm-install --skip-pi
npm install --prefix /root/.node-red node-red-node-watson
npm install --prefix /root/.node-red node-red-contrib-startup-trigger
openssl req -nodes -newkey rsa:2048 -keyout /root/.node-red/node-key.pem -out /root/.node-red/node-csr.pem -subj "/C=US/ST=Dallas/L=Dallas/O=Global Security/OU=IT Department/CN=$(curl -s ipinfo.io/ip)"
openssl x509 -req -in /root/.node-red/node-csr.pem -signkey /root/.node-red/node-key.pem -out /root/.node-red/node-cert.pem

curl -d "Instance=$(< /root/instnum.txt)&Log=Starting Data Aggregator" -X POST https://daidemos.com/log
wget -O /root/da/package.json https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/package.json
wget -O /root/da/data_aggregator.js https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/data_aggregator.js
wget -O /root/da/bg.js https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/bg.js
wget -O /root/tsend https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/scripts/tsend
chmod +x /root/tsend
npm --prefix /root/da install /root/da
node /root/da/bg.js "$(< /root/companyurl.txt)" &
(node /root/da/data_aggregator.js "$(< /root/companyurl.txt)" > /var/log/dataaggregator.log 2>&1 ) &




