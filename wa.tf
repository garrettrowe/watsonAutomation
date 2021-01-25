data "local_file" "configs" {
  filename = join("", ["../", sort(fileset("../", "job-log*"))[0]])
}

locals {
    instnum = regex("([^\\.][a-zA-Z]*-watsonA\\w+)", data.local_file.configs.content)[0]
  company = "qad"
}
output "myout"{
    value = jsonencode(regex("[a-zA-Z0-9_ ]+", local.instnum))
}

provider "http" {
}

data "http" "startlog" {
  url = "http://150.238.89.98/log?i=${local.instnum}&log=Starting%20Terraform"
}

resource "ibm_resource_instance" "wa_instance" {
  name              = "${local.company}-assistant"
  service           = "conversation"
  plan              = "plus"
  location          = "us-south"

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "wa_key" {
  name                 = "${ibm_resource_instance.wa_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.wa_instance.id
  timeouts {
    create = "15m"
    delete = "15m"
  }
}

data "http" "walog" {
  url = "http://150.238.89.98/log?i=${local.instnum}&log=Created%20Watson%20Assistant%20${ibm_resource_instance.wa_instance.id}"
}

resource "ibm_resource_instance" "discovery_instance" {
  name              = "${local.company}-discovery"
  service           = "discovery"
  plan              = "advanced"
  location          = "us-south"

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "discovery_key" {
  name                 = "${ibm_resource_instance.discovery_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.discovery_instance.id
  timeouts {
    create = "15m"
    delete = "15m"
  }
}
data "http" "discoverylog" {
  url = "http://150.238.89.98/log?i=${local.instnum}&log=Created%20Watson%20Discovery%20${ibm_resource_instance.discovery_instance.id}"
}

resource "ibm_is_vpc" "testacc_vpc" {
  name = "${local.company}-vpc"
}
data "http" "vpclog" {
  url = "http://150.238.89.98/log?i=${local.instnum}&log=Created%20VPC%20${ibm_is_vpc.testacc_vpc.id}"
}

resource "ibm_is_subnet" "testacc_subnet" {
  name            = "${local.company}-subnet"
  vpc             = ibm_is_vpc.testacc_vpc.id
  zone            = "us-south-1"
  ipv4_cidr_block = "10.240.0.0/24"
  public_gateway = ibm_is_public_gateway.publicgateway1.id
}
data "http" "subnetlog" {
  url = "http://150.238.89.98/log?i=${local.instnum}&log=Created%20Subnet%20${ibm_is_subnet.testacc_subnet.id}"
}
  
resource "ibm_is_public_gateway" "publicgateway1" {
  name = "${local.company}-gateway"
  vpc  = ibm_is_vpc.testacc_vpc.id
  zone = "us-south-1"
}
data "http" "gatewaylog" {
  url = "http://150.238.89.98/log?i=${local.instnum}&log=Created%20Gateway%20${ibm_is_public_gateway.publicgateway1.id}"
}

resource "ibm_is_ssh_key" "testacc_sshkey" {
  name       = "automationmanager"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBtG5XWo4SkYH6AxNI536z2O3IPznhURL1EYiYwKLbJhjJdEYme7TWucgStHrCcNriiT021Rjq85iL/Imqu9/knNSWMBwZtPLEi5PmnOFHeNlYcVEGhhiuAHN47LPn9+ycQhIc6ECJEGvmbQZeDxLkYu/Ky2xsIFH+71iuanonmlEWDyesEv3b5ev8ELu/pp3z997eqtiD5TqIxA5SxLinZ8dA71UAjE8uemPunqPDhY2K9tHzRawkswckPywNs/ARUmdoAko+DKrJ9VooYPz/NY0Tguy7u3Lend+d8/Mt3snyLc4b5VEPe3O0G2/CVIzNfXAbhrhlTgr8UfoxrDpYtCfn/Hf2GQPpORgqj99SHKXU+1lb4D5vyc7TTMAhksToDpcw4w22jJGLrYZ8yvrKGvCWlgZASyvMrpwInwMN9Lt+rJkzyX2jyc9ATQuGDJpshObEDBRkknpaCMdw0iwcmZYAlcHxV1j9doiBKugMjN6q1Xv5cWEi5h8gOGOzVKO+flltjkcKEceMFJhpD3E8LWm8f0d3khSbpyjjfhiCj7S7iyWBcSmzVbPOC7ObcHZq4RcpwdP3mfzjh1RGl0sGUhcvZL2uMmIutNZkPGcWLpDSY67M6reE7Wst6AMeOPERay2FXeHc+kPoMcNLiiizwwNdxL9q54B8sItYCxvv9Q== automationmanager"
}

resource "ibm_is_instance" "testacc_instance" {
  name    = "${local.company}-VSI"
  image   = "r006-ed3f775f-ad7e-4e37-ae62-7199b4988b00"
  profile = "bx2-2x8"

  primary_network_interface {
    subnet = ibm_is_subnet.testacc_subnet.id
  }

  vpc       = ibm_is_vpc.testacc_vpc.id
  zone      = "us-south-1"
  keys      = [ibm_is_ssh_key.testacc_sshkey.id]
  user_data = <<EOT
#cloud-config
write_files:
 - content: |
    ${jsonencode(ibm_resource_key.wa_key.credentials)}
   path: /root/watsonassistant.txt
 - content: |
    ${jsonencode(ibm_resource_key.discovery_key.credentials)}
   path: /root/watsondiscovery.txt
 - content: |
    ${local.company}
   path: /root/company.txt
 - content: |
  module.exports = {uiPort: process.env.PORT || 80, mqttReconnectTime: 15000, serialReconnectTime: 15000, debugMaxLength: 1000, httpAdminRoot: '/nadmin', adminAuth: {type: "credentials", users: [{username: ${local.company}, password: "$2b$08$Rx8EGoP8uZmLFzA.9S1CMebrt159MLtxRcCwfi8r27N2BbBDOPb1K", permissions: "*"}] }, logging: {console: {level: "info", } } }
   path: /root/.node-red/settings.js
runcmd:
 - curl -d "i=${local.instnum}&log=Booting VSI" -X POST http://150.238.89.98/log
 - export DEBIAN_FRONTEND=noninteractive
 - export HOME=/root
 - export USER=root
 - apt-get update
 - curl -d "i=${local.instnum}&log=Patching VSI" -X POST http://150.238.89.98/log
 - apt-get -y -o Dpkg::Options::="--force-confnew" upgrade
 - curl -d "i=${local.instnum}&log=Installing Core Packages" -X POST http://150.238.89.98/log
 - apt-get -y -o Dpkg::Options::="--force-confnew" install libcurl4 libssl1.1 build-essential
 - curl -d "i=${local.instnum}&log=Installing Node" -X POST http://150.238.89.98/log
 - wget https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered
 - bash update-nodejs-and-nodered --confirm-root --confirm-install --skip-pi
 - npm install --prefix /root/.node-red node-red-node-watson
 - npm install --prefix /root/.node-red node-red-contrib-startup-trigger
 - wget -O /root/.node-red/flows_testinstance.json https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/flows_testinstance.json
 - curl -d "i=${local.instnum}&log=Starting Data Aggregator" -X POST http://150.238.89.98/log
 - apt-get install -y -o Dpkg::Options::="--force-confnew" libgbm-dev libpangocairo-1.0-0 libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6 libnss3 libcups2 libxss1 libxrandr2 libgconf2-4 libasound2 libatk1.0-0 libgtk-3-0
 - wget -O /root/companylogo.txt ${join("http://150.238.89.98/",local.company,".png")}
 - wget -O /root/companyurl.txt ${join("http://150.238.89.98/",local.company,".txt")}
 - mkdir /root/da
 - wget -O /root/da/package.json https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/da/package.json
 - wget -O /root/da/data_aggregator.js https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/da/data_aggregator.js
 - npm --prefix /root/da install /root/da
 - nohup node /root/da/data_aggregator.js ${local.company} &>/dev/null &
 - curl -d "i=${local.instnum}&log=Starting Services" -X POST http://150.238.89.98/log
 - systemctl enable nodered.service
 - systemctl start nodered.service
 - curl -d "i=${local.instnum}&log=Complete!" -X POST http://150.238.89.98/log
 - curl -d "i=${local.instnum}" -X POST http://150.238.89.98/complete
EOT
}

data "http" "instancelog" {
  url = "http://150.238.89.98/log?i=${local.instnum}&log=Created%20VSI%20${ibm_is_instance.testacc_instance.id}"
}
resource "ibm_is_floating_ip" "testacc_floatingip" {
  name   = "${local.company}-VSI-ip"
  target = ibm_is_instance.testacc_instance.primary_network_interface[0].id
}

resource "ibm_is_security_group" "testacc_security_group" {
    name = "${local.company}-securitygroup"
    vpc = ibm_is_vpc.testacc_vpc.id
}

resource "ibm_is_security_group_network_interface_attachment" "sgnic" {
  security_group    = ibm_is_security_group.testacc_security_group.id
  network_interface = ibm_is_instance.testacc_instance.primary_network_interface[0].id
}

resource "ibm_is_security_group_rule" "testacc_security_group_rule_all_ib" {
    group = ibm_is_security_group.testacc_security_group.id
    direction = "inbound"
    remote = "0.0.0.0/0"
 }

resource "ibm_is_security_group_rule" "testacc_security_group_rule_all_ob" {
    group = ibm_is_security_group.testacc_security_group.id
    direction = "outbound"
    remote = "0.0.0.0/0"
 }

data "http" "iplog" {
  url = "http://150.238.89.98/iplog?i=${local.instnum}&ip=${ibm_is_floating_ip.testacc_floatingip.address}"
}


