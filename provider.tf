variable "ibmcloud_api_key" {
  description = "Cloud account API Key"
  default = "Generate a key and paste it → /n/n  https://cloud.ibm.com/iam/apikeys"
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
