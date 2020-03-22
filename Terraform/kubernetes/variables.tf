variable "profile" {
  default = "default"
}

variable "region" {
  default = "us-east-1"
}

variable "instance" {
  default = "t2.micro"
}

variable "instance_count" {
  default = "2"
}

variable "public_key" {
  default = "~/.ssh/MyKeyPair.pub"
}

variable "private_key" {
  default = "~/.ssh/MyKeyPair.pem"
}

variable "ansible_user" {
  default = "ubuntu"
}

variable "amis" {
  default = {
    us-east-1 = "ami-07ebfd5b3428b6f4d" # N. Virginia    
  }
}

variable "ami" {
  default = "ami-07ebfd5b3428b6f4d"
}