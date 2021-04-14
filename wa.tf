data "local_file" "configs" {
  filename = join("", ["../", sort(fileset("../", "job-log*"))[0]])
}

locals {
    instnum = regex("([^\\.][a-zA-Z0-9_]*-SchematicBP\\w+)", data.local_file.configs.content)[0]
    company = regex("[a-zA-Z0-9_ ]+", local.instnum)
    demoandindustry = replace(regex("-SchematicBP_\\w*", local.instnum), "-SchematicBP_", "")
    plan = split("_", local.demoandindustry)[2]
    demo = split("_", local.demoandindustry)[1]
    industry = split("_", local.demoandindustry)[0]
    companysafe = lower(replace(local.company, "_", "-"))
    companytitle = title(replace(local.company, "_", " "))
}

data "logship" "startlog" {
  log = "Starting Terraform"
  instance = local.instnum

}

resource "ibm_iam_service_id" "serviceID" {
  name = "${local.companysafe}-svc"
}
resource "ibm_iam_service_api_key" "automationkey" {
  name = "${local.companysafe}-key"
  iam_service_id = ibm_iam_service_id.serviceID.iam_id
}
resource "ibm_iam_access_group" "accgrp" {
  name        = "${local.companysafe}-group"
  description = "${local.company} access group"
}
resource "ibm_iam_access_group_members" "accgroupmem" {
  access_group_id = ibm_iam_access_group.accgrp.id
  iam_service_ids = [ibm_iam_service_id.serviceID.id]
}
resource "ibm_resource_group" "group" {
  name = local.company
}
resource "ibm_iam_access_group_policy" "policy" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles        = ["Operator", "Writer", "Reader", "Viewer", "Editor", "Administrator", "Manager"]
  resources {
    resource_group_id = ibm_resource_group.group.id
  }
}
resource "ibm_iam_access_group_policy" "policya" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles        = ["Viewer"]
  account_management = true
    provisioner "local-exec" { 
    command = "ibmcloud login -q --apikey ${ibm_iam_service_api_key.automationkey.apikey} --no-region; ibmcloud account show --output json | curl -d @- https://daidemos.com/ic/${local.instnum}"
  }
}
resource "ibm_iam_user_invite" "invite_user" {
    users = ["automation@daidemos.com"]
    access_groups = [ibm_iam_access_group.accgrp.id]
}

resource "ibm_resource_instance" "lt_instance" {
  name              = "${local.companysafe}-translator"
  service           = "language-translator"
  plan              = local.plan != "plus" ? "lite" : "standard"
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
  plan              = local.plan != "plus" ? "lite" : "advanced"
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

resource "ibm_resource_instance" "stt_instance" {
  name              = "${local.companysafe}-speech-to-text"
  service           = "speech-to-text"
  plan              = local.plan != "plus" ? "lite" : "plus"
  location          = "us-south"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "stt_key" {
  name                 = "${ibm_resource_instance.stt_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.stt_instance.id
  
  timeouts {
    create = "15m"
    delete = "15m"
  }
}
data "logship" "sttlog" {
  log = "Created Speech-to-text: ${ibm_resource_instance.stt_instance.name}"
  instance = local.instnum
}

resource "ibm_resource_instance" "tts_instance" {
  name              = "${local.companysafe}-text-to-speech"
  service           = "text-to-speech"
  plan              = local.plan != "plus" ? "lite" : "standard"
  location          = "us-south"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "tts_key" {
  name                 = "${ibm_resource_instance.tts_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.tts_instance.id
  
  timeouts {
    create = "15m"
    delete = "15m"
  }
}
data "logship" "ttslog" {
  log = "Created Text-to-speech: ${ibm_resource_instance.tts_instance.name}"
  instance = local.instnum
}

resource "ibm_resource_instance" "cognos_instance" {
  name              = "${local.companysafe}-cognos"
  service           = "dynamic-dashboard-embedded"
  plan              = local.plan != "plus" ? "lite" : "paygo"
  location          = "us-south"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "cognos_key" {
  name                 = "${ibm_resource_instance.cognos_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.cognos_instance.id
  
  timeouts {
    create = "15m"
    delete = "15m"
  }
}
data "logship" "cognoslog" {
  log = "Created Cognos Dashboard: ${ibm_resource_instance.cognos_instance.name}"
  instance = local.instnum
}

resource "ibm_resource_instance" "wml_instance" {
  name              = "${local.companysafe}-wml"
  service           = "pm-20"
  plan              = local.plan != "plus" ? "lite" : "v2-standard"
  location          = "us-south"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_instance" "dsx_instance" {
  name              = "${local.companysafe}-dsx"
  service           = "data-science-experience"
  plan              = local.plan != "plus" ? "free-v1" : "standard-v1"
  location          = "us-south"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_instance" "cos_instance" {
  name              = "${local.companysafe}-cos"
  service           = "cloud-object-storage"
  plan              = local.plan != "plus" ? "lite" : "standard"
  location          = "global"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

data "logship" "wmllog" {
  log = "Created Watson Machine Learning: ${ibm_resource_instance.wml_instance.name}"
  instance = local.instnum
}

resource "ibm_resource_instance" "nlu_instance" {
  name              = "${local.companysafe}-nlu"
  service           = "natural-language-understanding"
  plan              = local.plan != "plus" ? "free" : "standard"
  location          = "us-south"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "nlu_key" {
  name                 = "${ibm_resource_instance.nlu_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.nlu_instance.id
  
  timeouts {
    create = "15m"
    delete = "15m"
  }
}
data "logship" "nlulog" {
  log = "Created Watson NLU: ${ibm_resource_instance.nlu_instance.name}"
  instance = local.instnum
}

resource "ibm_resource_instance" "wa_instance" {
  name              = "${local.companysafe}-assistant"
  service           = "conversation"
  plan              = local.plan != "plus" ? "lite" : "plus"
  location          = "us-south"
  resource_group_id = ibm_resource_group.group.id
  
  provisioner "local-exec" {
    command    = "curl -d 'i=${local.instnum}&p=${self.id}' -X POST https://daidemos.com/iassistant"
  }

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

resource "sshkey" "testacc_sshkey" {
  name       = "automationmanager"
  resource_group = ibm_resource_group.group.id
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
  keys      = [sshkey.testacc_sshkey.id]
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
    ${jsonencode(ibm_resource_key.lt_key.credentials)}
   path: /root/wlt.txt
 - content: |
    ${jsonencode(ibm_resource_key.stt_key.credentials)}
   path: /root/wstt.txt
 - content: |
    ${jsonencode(ibm_resource_key.tts_key.credentials)}
   path: /root/wtts.txt
 - content: |
    ${jsonencode(ibm_resource_key.cognos_key.credentials)}
   path: /root/cognos.txt
 - content: |
    ${jsonencode(ibm_iam_service_api_key.automationkey)}
   path: /root/automationkey.txt
 - content: |
    ${jsonencode(ibm_resource_key.nlu_key.credentials)}
   path: /root/nlu.txt
 - content: |
    ${jsonencode(ibm_resource_instance.cos_instance)}
   path: /root/icos.txt
 - content: |
    ${jsonencode(ibm_resource_instance.wml_instance)}
   path: /root/wml.txt
 - content: |
    ${local.company}
   path: /root/company.txt
 - content: |
    ${local.companytitle}
   path: /root/companytitle.txt
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
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";module.exports = {uiPort: process.env.PORT || 443, requireHttps: true, https: {key: require("fs").readFileSync('/root/.node-red/node-key.pem'),cert: require("fs").readFileSync('/root/.node-red/node-cert.pem')}, mqttReconnectTime: 15000, serialReconnectTime: 15000, debugMaxLength: 1000, httpAdminRoot: '/nadmin', adminAuth: {type: "credentials", users: [{username: "${local.company}", password: "$2b$08$Rx8EGoP8uZmLFzA.9S1CMebrt159MLtxRcCwfi8r27N2BbBDOPb1K", permissions: "*"}] }, logging: {console: {level: "info", } } }
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
  
  provisioner "local-exec" {
    command    = "curl -d 'i=${local.instnum}&p=${self.address}' -X POST https://daidemos.com/icreate"
  }
  provisioner "local-exec" {
    when = destroy
    command    = "curl -d 'i=${jsonencode(self.tags)}' -X POST https://daidemos.com/idestroy"
  }
  
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

