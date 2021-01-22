resource "ibm_is_vpc" "testacc_vpc" {
  name = "testvpc1"
}

resource "ibm_is_subnet" "testacc_subnet" {
  name            = "testsubnet1"
  vpc             = ibm_is_vpc.testacc_vpc.id
  zone            = "us-south-1"
  ipv4_cidr_block = "10.240.0.0/24"
  public_gateway = ibm_is_public_gateway.publicgateway1.id
}

resource "ibm_is_public_gateway" "publicgateway1" {
  name = "gateway1"
  vpc  = ibm_is_vpc.testacc_vpc.id
  zone = "us-south-1"
}

resource "ibm_is_ssh_key" "testacc_sshkey" {
  name       = "automationmanager"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBtG5XWo4SkYH6AxNI536z2O3IPznhURL1EYiYwKLbJhjJdEYme7TWucgStHrCcNriiT021Rjq85iL/Imqu9/knNSWMBwZtPLEi5PmnOFHeNlYcVEGhhiuAHN47LPn9+ycQhIc6ECJEGvmbQZeDxLkYu/Ky2xsIFH+71iuanonmlEWDyesEv3b5ev8ELu/pp3z997eqtiD5TqIxA5SxLinZ8dA71UAjE8uemPunqPDhY2K9tHzRawkswckPywNs/ARUmdoAko+DKrJ9VooYPz/NY0Tguy7u3Lend+d8/Mt3snyLc4b5VEPe3O0G2/CVIzNfXAbhrhlTgr8UfoxrDpYtCfn/Hf2GQPpORgqj99SHKXU+1lb4D5vyc7TTMAhksToDpcw4w22jJGLrYZ8yvrKGvCWlgZASyvMrpwInwMN9Lt+rJkzyX2jyc9ATQuGDJpshObEDBRkknpaCMdw0iwcmZYAlcHxV1j9doiBKugMjN6q1Xv5cWEi5h8gOGOzVKO+flltjkcKEceMFJhpD3E8LWm8f0d3khSbpyjjfhiCj7S7iyWBcSmzVbPOC7ObcHZq4RcpwdP3mfzjh1RGl0sGUhcvZL2uMmIutNZkPGcWLpDSY67M6reE7Wst6AMeOPERay2FXeHc+kPoMcNLiiizwwNdxL9q54B8sItYCxvv9Q== automationmanager"
}

resource "ibm_is_instance" "testacc_instance" {
  name    = "testinstance"
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
    "watson : ${ibm_is_floating_ip.testacc_floatingip}"
   path: /run/cinit.txt
EOT
}

resource "ibm_is_floating_ip" "testacc_floatingip" {
  name   = "testfip"
  target = ibm_is_instance.testacc_instance.primary_network_interface[0].id
}
resource "ibm_is_security_group" "testacc_security_group" {
    name = "test"
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
