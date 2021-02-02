variable "url_override" {
  description = "Override the corporate website URL here."
  default = "null"
}
module "logship" {
  source = "github.com/garrettrowe/logship"
}


terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "~> 1.19.0"
    }
    logship = {
      source = "github.com/garrettrowe/logship"
    }
  }
}

provider "http" {
}
provider "logship" {
}
provider "ibm" {
  generation         = 2
  region             = "us-south"
}
