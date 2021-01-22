variable "ibmcloud_api_key" {
  description = "Cloud account API Key"
  default = "<a href='https://cloud.ibm.com/iam/apikeys'>Generate a Key</a>"
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
  ibmcloud_api_key   = var.ibmcloud_api_key
  generation         = 2
  region             = "us-south"
}
