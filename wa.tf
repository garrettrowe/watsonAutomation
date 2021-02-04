data "local_file" "configs" {
  filename = join("", ["../", sort(fileset("../", "job-log*"))[0]])
}

locals {
    instnum = regex("([^\\.][a-zA-Z0-9_]*-SchematicBP\\w+)", data.local_file.configs.content)[0]
    company = regex("[a-zA-Z0-9_ ]+", local.instnum)
    demoandindustry = replace(regex("-SchematicBP_\\w*", local.instnum), "-SchematicBP_", "")
    demo = split("_", local.demoandindustry)[1]
    industry = split("_", local.demoandindustry)[0]
    companysafe = lower(replace(local.company, "_", "-"))
}

data "logship" "startlog" {
  log = "Starting Terraform"
  instance = local.instnum
}

resource "ibm_iam_access_group" "accgrp" {
  name        = "${local.companysafe}-group"
  description = "${local.company} access group"
}
resource "ibm_resource_group" "group" {
  name = local.company
}
resource "ibm_iam_access_group_policy" "policy" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles        = ["Operator", "Writer", "Reader", "Viewer", "Editor"]

  resources {
    resource_group_id = ibm_resource_group.group.id
  }
}
resource "ibm_iam_user_invite" "invite_user" {
    users = ["automation@daidemos.com"]
    access_groups = [ibm_iam_access_group.accgrp.id]
}

resource "ibm_resource_instance" "lt_instance" {
  name              = "${local.companysafe}-translator"
  service           = "language-translator"
  plan              = "standard"
  location          = "us-south"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "lt_key" {
  name                 = "${ibm_resource_instance.lt_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.lt_instance.id
  
  timeouts {
    create = "15m"
    delete = "15m"
  }
}
data "logship" "ltlog" {
  log = "Created Watson Language Translator: ${ibm_resource_instance.lt_instance.name}"
  instance = local.instnum
}

resource "ibm_resource_instance" "discovery_instance" {
  name              = "${local.companysafe}-discovery"
  service           = "discovery"
  plan              = "advanced"
  location          = "us-south"
  resource_group_id = ibm_resource_group.group.id

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

resource "ibm_resource_instance" "wa_instance" {
  name              = "${local.companysafe}-assistant"
  service           = "conversation"
  plan              = "plus"
  location          = "us-south"
  resource_group_id = ibm_resource_group.group.id

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



resource "ibm_is_vpc" "testacc_vpc" {
  name = "${local.companysafe}-vpc"
  resource_group = ibm_resource_group.group.id
}
data "logship" "vpclog" {
  log = "Created VPC: ${ibm_is_vpc.testacc_vpc.name}"
  instance = local.instnum
}

resource "ibm_is_subnet" "testacc_subnet" {
  name            = "${local.companysafe}-subnet"
  vpc             = ibm_is_vpc.testacc_vpc.id
  resource_group  = ibm_resource_group.group.id
  zone            = "us-south-1"
  ipv4_cidr_block = "10.240.0.0/24"
  public_gateway  = ibm_is_public_gateway.publicgateway1.id
}
data "logship" "subnetlog" {
  log = "Created Subnet: ${ibm_is_subnet.testacc_subnet.name}"
  instance = local.instnum
}
  
resource "ibm_is_public_gateway" "publicgateway1" {
  name = "${local.companysafe}-gateway"
  vpc  = ibm_is_vpc.testacc_vpc.id
  zone = "us-south-1"
  resource_group = ibm_resource_group.group.id
}
data "logship" "gatewaylog" {
  log = "Created Gateway: ${ibm_is_public_gateway.publicgateway1.name}"
  instance = local.instnum
}

resource "ibm_is_ssh_key" "testacc_sshkey" {
  name       = "automation"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBtG5XWo4SkYH6AxNI536z2O3IPznhURL1EYiYwKLbJhjJdEYme7TWucgStHrCcNriiT021Rjq85iL/Imqu9/knNSWMBwZtPLEi5PmnOFHeNlYcVEGhhiuAHN47LPn9+ycQhIc6ECJEGvmbQZeDxLkYu/Ky2xsIFH+71iuanonmlEWDyesEv3b5ev8ELu/pp3z997eqtiD5TqIxA5SxLinZ8dA71UAjE8uemPunqPDhY2K9tHzRawkswckPywNs/ARUmdoAko+DKrJ9VooYPz/NY0Tguy7u3Lend+d8/Mt3snyLc4b5VEPe3O0G2/CVIzNfXAbhrhlTgr8UfoxrDpYtCfn/Hf2GQPpORgqj99SHKXU+1lb4D5vyc7TTMAhksToDpcw4w22jJGLrYZ8yvrKGvCWlgZASyvMrpwInwMN9Lt+rJkzyX2jyc9ATQuGDJpshObEDBRkknpaCMdw0iwcmZYAlcHxV1j9doiBKugMjN6q1Xv5cWEi5h8gOGOzVKO+flltjkcKEceMFJhpD3E8LWm8f0d3khSbpyjjfhiCj7S7iyWBcSmzVbPOC7ObcHZq4RcpwdP3mfzjh1RGl0sGUhcvZL2uMmIutNZkPGcWLpDSY67M6reE7Wst6AMeOPERay2FXeHc+kPoMcNLiiizwwNdxL9q54B8sItYCxvv9Q== automationmanager"
}

resource "ibm_is_instance" "testacc_instance" {
  name    = "${local.companysafe}-vsi"
  image   = "r006-ed3f775f-ad7e-4e37-ae62-7199b4988b00"
  profile = "bx2-2x8"
  resource_group = ibm_resource_group.group.id

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
    ${local.companysafe}
   path: /root/companysafe.txt
 - content: |
    ${var.url_override}
   path: /root/companyurloverride.txt
 - content: |
    ${local.instnum}
   path: /root/instnum.txt
 - content: |
    ${local.demo}
   path: /root/demo.txt
 - content: |
    ${local.industry}
   path: /root/industry.txt
 - content: |
    module.exports = {uiPort: process.env.PORT || 80, mqttReconnectTime: 15000, serialReconnectTime: 15000, debugMaxLength: 1000, httpAdminRoot: '/nadmin', adminAuth: {type: "credentials", users: [{username: "${local.company}", password: "$2b$08$Rx8EGoP8uZmLFzA.9S1CMebrt159MLtxRcCwfi8r27N2BbBDOPb1K", permissions: "*"}] }, logging: {console: {level: "info", } } }
   path: /root/.node-red/settings.js
runcmd:
 - wget https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/scripts/base.sh
 - bash base.sh
 - wget https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/scripts/${local.demo}.sh
 - bash ${local.demo}.sh
EOT
}
data "logship" "instancelog" {
  log = "Created VSI: ${ibm_is_instance.testacc_instance.name}"
  instance = local.instnum
}

resource "ibm_is_floating_ip" "testacc_floatingip" {
  name   = "${local.companysafe}-vsi-ip"
  resource_group = ibm_resource_group.group.id
  target = ibm_is_instance.testacc_instance.primary_network_interface[0].id
}

resource "ibm_is_security_group" "testacc_security_group" {
    name = "${local.companysafe}-securitygroup"
    resource_group = ibm_resource_group.group.id
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

