provider "aws" {
  shared_credentials_file = "/home/shadow2/.aws/credentials"
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami = "ami-0fc61db8544a617ed"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.deployer.key_name}"
  security_groups = ["${aws_security_group.allow_ssh.name}"]
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPKKx0Sj/9Cg0CDrjHmPdmQLwGd16p2w5ErT6DmtZlauXSYnxp8mjkbQ4GkAOVUuD5yh1Aw2zIM1Umn0gVcLDahSe2eAfeKOiKkKMRUHRxF6qta2Jjgk6cNnq/K2FRpzoZcVCQsQ9tEAaE7rfk+3tDdePbdLIIHjIOje07dzyV7Su6taJ90Jxbuil0/HowfykkvE9NFXuqi5Wc2bc4kD1XL0PFYSge/XZ9748RN4qEAAi1NUxJERMxdP686/evEg1rlq32dI1eh6UckQRK7uObTjtbfTblF8mGrMRhdkB4DHR2LFRIpIHjDH5BbLCRArB4L+C9SjVE7x5W+lbWfmqj"
}

resource "aws_security_group" "allow_ssh"{
  name = "allow_ssh"
    ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
      from_port = 0
      to_port = 0
      protocol = -1
      cidr_blocks = ["0.0.0.0/0"]
  }
}

output "example_public_dns" {
  value = "${aws_instance.example.public_dns}"
}
