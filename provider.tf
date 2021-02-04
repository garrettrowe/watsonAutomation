variable "url_override" {
  description = "Override the corporate website URL here."
  default = "null"
}

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "~> 1.19.0"
    }
    logship = {
      source = "garrettrowe/logship"
      version = "0.0.4"
    }
    sshkey = {
      source = "garrettrowe/sshkey"
      version = "0.2"
    }
  }
}
provider "logship" {
}
provider "ibm" {
  generation         = 2
  region             = "us-south"
}
provider "sshkey" {
  generation         = 2
  region             = "us-south"
}
