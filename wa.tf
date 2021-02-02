data "local_file" "configs" {
  filename = join("", ["../", sort(fileset("../", "job-log*"))[0]])
}

locals {
    instnum = regex("([^\\.][a-zA-Z0-9_]*-watsonA\\w+)", data.local_file.configs.content)[0]
    company = regex("[a-zA-Z0-9_ ]+", local.instnum)
    demo = regex("(?<=-)[0-9a-zA-Z]+[^_]", local.instnum)
    companysafe = lower(replace(local.company, "_", "-"))
}
output "ffgf"{
  value = local.demo
}

data "logship" "startlog" {
  log = "Starting Terraform"
  instance = local.instnum
}

resource "ibm_resource_instance" "wa_instance" {
  name              = "${local.companysafe}-assistant"
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

data "logship" "walog" {
  log = "Created Watson Assistant: ${ibm_resource_instance.wa_instance.name}"
  ip = ibm_resource_instance.wa_instance.id
  instance = local.instnum
}

resource "ibm_resource_instance" "discovery_instance" {
  name              = "${local.companysafe}-discovery"
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
data "logship" "discoverylog" {
  log = "Created Watson Discovery: ${ibm_resource_instance.discovery_instance.name}"
  instance = local.instnum
}

resource "ibm_is_vpc" "testacc_vpc" {
  name = "${local.companysafe}-vpc"
}
data "logship" "vpclog" {
  log = "Created VPC: ${ibm_is_vpc.testacc_vpc.name}"
  instance = local.instnum
}

resource "ibm_is_subnet" "testacc_subnet" {
  name            = "${local.companysafe}-subnet"
  vpc             = ibm_is_vpc.testacc_vpc.id
  zone            = "us-south-1"
  ipv4_cidr_block = "10.240.0.0/24"
  public_gateway = ibm_is_public_gateway.publicgateway1.id
}
data "logship" "subnetlog" {
  log = "Created Subnet: ${ibm_is_subnet.testacc_subnet.name}"
  instance = local.instnum
}
  
resource "ibm_is_public_gateway" "publicgateway1" {
  name = "${local.companysafe}-gateway"
  vpc  = ibm_is_vpc.testacc_vpc.id
  zone = "us-south-1"
}
data "logship" "gatewaylog" {
  log = "Created Gateway: ${ibm_is_public_gateway.publicgateway1.name}"
  instance = local.instnum
}

resource "ibm_is_ssh_key" "testacc_sshkey" {
  name       = "automationmanager"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBtG5XWo4SkYH6AxNI536z2O3IPznhURL1EYiYwKLbJhjJdEYme7TWucgStHrCcNriiT021Rjq85iL/Imqu9/knNSWMBwZtPLEi5PmnOFHeNlYcVEGhhiuAHN47LPn9+ycQhIc6ECJEGvmbQZeDxLkYu/Ky2xsIFH+71iuanonmlEWDyesEv3b5ev8ELu/pp3z997eqtiD5TqIxA5SxLinZ8dA71UAjE8uemPunqPDhY2K9tHzRawkswckPywNs/ARUmdoAko+DKrJ9VooYPz/NY0Tguy7u3Lend+d8/Mt3snyLc4b5VEPe3O0G2/CVIzNfXAbhrhlTgr8UfoxrDpYtCfn/Hf2GQPpORgqj99SHKXU+1lb4D5vyc7TTMAhksToDpcw4w22jJGLrYZ8yvrKGvCWlgZASyvMrpwInwMN9Lt+rJkzyX2jyc9ATQuGDJpshObEDBRkknpaCMdw0iwcmZYAlcHxV1j9doiBKugMjN6q1Xv5cWEi5h8gOGOzVKO+flltjkcKEceMFJhpD3E8LWm8f0d3khSbpyjjfhiCj7S7iyWBcSmzVbPOC7ObcHZq4RcpwdP3mfzjh1RGl0sGUhcvZL2uMmIutNZkPGcWLpDSY67M6reE7Wst6AMeOPERay2FXeHc+kPoMcNLiiizwwNdxL9q54B8sItYCxvv9Q== automationmanager"
}

resource "ibm_is_instance" "testacc_instance" {
  name    = "${local.companysafe}-vsi"
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
    ${var.url_override}
   path: /root/companyurloverride.txt
 - content: |
    module.exports = {uiPort: process.env.PORT || 80, mqttReconnectTime: 15000, serialReconnectTime: 15000, debugMaxLength: 1000, httpAdminRoot: '/nadmin', adminAuth: {type: "credentials", users: [{username: "${local.company}", password: "$2b$08$Rx8EGoP8uZmLFzA.9S1CMebrt159MLtxRcCwfi8r27N2BbBDOPb1K", permissions: "*"}] }, logging: {console: {level: "info", } } }
   path: /root/.node-red/settings.js
runcmd:
 - curl -d "Instance=${local.instnum}&Log=Booting VSI" -X POST https://daidemos.com/log
 - mkdir /root/demo
 - mkdir /root/da
 - export DEBIAN_FRONTEND=noninteractive
 - export HOME=/root
 - export USER=root
 - apt-get update
 - curl -d "Instance=${local.instnum}&Log=Patching VSI" -X https://daidemos.com/log
 - apt-get -y -o Dpkg::Options::="--force-confnew" upgrade
 - curl -d "i=${local.instnum}&Log=Installing Core Packages" -X POST https://daidemos.com/log
 - apt-get -y -o Dpkg::Options::="--force-confnew" install libcurl4 libssl1.1 build-essential fdupes
 - curl -d "Instance=${local.instnum}&Log=Installing Node" -X POST https://daidemos.com/log
 - wget https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered
 - bash update-nodejs-and-nodered --confirm-root --confirm-install --skip-pi
 - npm install --prefix /root/.node-red node-red-node-watson
 - npm install --prefix /root/.node-red node-red-contrib-startup-trigger
 - wget -O /root/.node-red/flows_${local.companysafe}-vsi.json https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/demos/watson/flows.json
 - curl -d "Instance=${local.instnum}&Log=Starting Data Aggregator" -X POST https://daidemos.com/log
 - apt-get install -y -o Dpkg::Options::="--force-confnew" libgbm-dev libpangocairo-1.0-0 libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6 libnss3 libcups2 libxss1 libxrandr2 libgconf2-4 libasound2 libatk1.0-0 libgtk-3-0
 - wget -O /root/companylogo.png https://daidemos.com/${local.company}.png
 - wget -O /root/companyurl.txt https://daidemos.com/${local.company}.txt
 - wget -O /root/da/package.json https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/package.json
 - wget -O /root/da/data_aggregator.js https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/data_aggregator.js
 - wget -O /root/da/bg.js https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/bg.js
 - npm --prefix /root/da install /root/da
 - curl -d "Instance=${local.instnum}&Log=Starting Services" -X POST https://daidemos.com/log
 - systemctl enable nodered.service
 - systemctl start nodered.service
 - curl -d "Instance=${local.instnum}&Log=Provision complete! Content loading and model training will occur in the background over the next few hours." -X POST https://daidemos.com/log
 - curl -d "Instance=${local.instnum}" -X POST https://daidemos.com/complete
EOT
}
data "logship" "instancelog" {
  log = "Created VSI: ${ibm_is_instance.testacc_instance.name}"
  instance = local.instnum
}

resource "ibm_is_floating_ip" "testacc_floatingip" {
  name   = "${local.companysafe}-vsi-ip"
  target = ibm_is_instance.testacc_instance.primary_network_interface[0].id
}

resource "ibm_is_security_group" "testacc_security_group" {
    name = "${local.companysafe}-securitygroup"
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
data "logship" "iplog" {
  ip = ibm_is_floating_ip.testacc_floatingip.address
  instance = local.instnum
}

