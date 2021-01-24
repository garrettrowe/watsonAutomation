
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
  }
}

provider "ibm" {
  generation         = 2
  region             = "us-south"
}
