resource "aws_key_pair" "demo_key" {
  key_name   = "MyKeyPair"
  public_key = "${file(var.public_key)}"

}

resource "aws_instance" "master" {
  count = "1"
  ami           = "${var.ami}"
  instance_type = "t2.medium"
  key_name      = "${aws_key_pair.demo_key.key_name}"

  vpc_security_group_ids = [
    "${aws_security_group.web.id}",
    "${aws_security_group.ssh.id}",
    "${aws_security_group.egress-tls.id}",
    "${aws_security_group.ping-ICMP.id}",
	"${aws_security_group.web_server.id}"
  ]

  connection {
    private_key = "${file(var.private_key)}"
    user        = "${var.ansible_user}"
    host     = "${self.public_ip}"
  }

  #user_data = "${file("../templates/install_jenkins.sh")}"

  # Ansible requires Python to be installed on the remote machine as well as the local machine.
  provisioner "remote-exec" {
    inline = ["sudo apt-get -qq install python -y"]
  }

  provisioner "local-exec" {
    command = ">cluster.ini;" 
  }

  provisioner "local-exec" {
    command = "echo [master] | tee -a cluster.ini;"
  }

  provisioner "local-exec" {
    command = "echo ${aws_instance.master[0].public_ip} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=${var.private_key} | tee -a cluster.ini;"   
  }

  provisioner "local-exec" {      
    command = "echo [workers] | tee -a cluster.ini;"
  }

  provisioner "local-exec" {
    command = "sleep 40;"
  }

  provisioner "local-exec" {      
    command = ">master.ini;"
  }

  provisioner "local-exec" {      
    command = "echo [master] | tee -a master.ini;"
  }

  provisioner "local-exec" {      
    command = "echo ${aws_instance.master[count.index].public_ip} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=${var.private_key} | tee -a master.ini;"
  }

  provisioner "local-exec" {      
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -u ${var.ansible_user} --private-key ${var.private_key} -i master.ini ../../Ansible/deploy_docker.yml"
  }

  provisioner "local-exec" {
    command = "sleep 180;"
  }

  provisioner "local-exec" {      
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -u ${var.ansible_user} --private-key ${var.private_key} -i cluster.ini ../../Ansible/deploy_kubernetes.yml"
  }

  tags = {
    Name     = "master-${count.index +1 }"
    Batch    = "7AM"
    Location = "N. Virginia"
  }
}

resource "aws_instance" "worker" {
  count = "${var.instance_count}"
  ami           = "${var.ami}"
  instance_type = "${var.instance}"
  key_name      = "${aws_key_pair.demo_key.key_name}"

  vpc_security_group_ids = [
    "${aws_security_group.web.id}",
    "${aws_security_group.ssh.id}",
    "${aws_security_group.egress-tls.id}",
    "${aws_security_group.ping-ICMP.id}",
	  "${aws_security_group.web_server.id}"
  ]

  connection {
    private_key = "${file(var.private_key)}"
    user        = "${var.ansible_user}"
    host     = "${self.public_ip}"
  }

  
  # Ansible requires Python to be installed on the remote machine as well as the local machine.
  provisioner "remote-exec" {
    inline = ["sudo apt-get -qq install python -y"]
  }

    # This is where we configure the instance with ansible-playbook
  # Install worker
  provisioner "local-exec" {
    command = "sleep 60;"
  }

  provisioner "local-exec" {
    command = ">worker.ini;"
  }

  provisioner "local-exec" {
    command = "echo [worker] | tee -a worker.ini;"
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=${var.private_key} | tee -a worker.ini;"
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=${var.private_key} | tee -a cluster.ini;"
  }

  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -u ${var.ansible_user} --private-key ${var.private_key} -i worker.ini ../../Ansible/deploy_docker.yml"
  }

  tags = {
    Name     = "worker-${count.index +1 }"
    Batch    = "7AM"
    Location = "N. Virginia"
  }
}

resource "aws_security_group" "web" {
  name        = "default-web-example"
  description = "Security group for web that allows web traffic from internet"
  #vpc_id      = "${aws_vpc.my-vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-example-default-vpc"
  }
}

resource "aws_security_group" "ssh" {
  name        = "default-ssh-example"
  description = "Security group for nat instances that allows SSH and VPN traffic from internet"
  #vpc_id      = "${aws_vpc.my-vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-example-default-vpc"
  }
}

resource "aws_security_group" "egress-tls" {
  name        = "default-egress-tls-example"
  description = "Default security group that allows inbound and outbound traffic from all instances in the VPC"
  #vpc_id      = "${aws_vpc.my-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "egress-tls-example-default-vpc"
  }
}

resource "aws_security_group" "ping-ICMP" {
  name        = "default-ping-example"
  description = "Default security group that allows to ping the instance"
  #vpc_id      = "${aws_vpc.my-vpc.id}"

  ingress {
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ping-ICMP-example-default-vpc"
  }
}

# Allow the web app to receive requests on port 8080
resource "aws_security_group" "web_server" {
  name        = "default-web_server-example"
  description = "Default security group that allows to use port 8080"
  #vpc_id      = "${aws_vpc.my-vpc.id}"
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_server-example-default-vpc"
  }
}