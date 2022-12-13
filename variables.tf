variable "host_os" {
  type    = string
  default = "linux"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "vpc_id" {
  type    = string
  default = "vpc-0a0a0a0a0a0a0a0a0"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}





