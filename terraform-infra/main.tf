provider "aws" {
  region = "eu-west-1"
  #shared_credentials_file = "~/.aws/credentials"
}

terraform {
  backend "s3" {
    bucket = "cyber94-oabu-bucket"
    key = "tfstate/calculator/terraform.tfstate"
    region = "eu-west-1"
    dynamodb_table = "cyber94_calculator_oabu_dynamodb_table_lock"
    encrypt = true
  }
}

# @component CalcApp:VPC (#vpc)
resource "aws_vpc" "cyber94_calculator_oabu_vpc_tf" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "cyber94_calculator_oabu_vpc"
  }
}

resource "aws_internet_gateway" "cyber94_calculator_oabu_igw_tf" {
  vpc_id = aws_vpc.cyber94_calculator_oabu_vpc_tf.id

  tags = {
    Name = "cyber94_calculator_oabu_igw"
  }
}

resource "aws_route_table" "cyber94_calculator_oabu_internet_rt_tf" {
  vpc_id = aws_vpc.cyber94_calculator_oabu_vpc_tf.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cyber94_calculator_oabu_igw_tf.id
  }

  tags = {
    Name = "cyber94_calculator_oabu_internet_rt"
  }
}

# @component CalcApp:VPC:Subnet (#subnet)
resource "aws_subnet" "cyber94_calculator_oabu_subnet_public_tf" {
  vpc_id = aws_vpc.cyber94_calculator_oabu_vpc_tf.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "cyber94_calculator_oabu_subnet_public"
  }
}

resource "aws_route_table_association" "cyber94_calculator_oabu_internet_rt_assoc_tf" {
  subnet_id = aws_subnet.cyber94_calculator_oabu_subnet_public_tf.id
  route_table_id = aws_route_table.cyber94_calculator_oabu_internet_rt_tf.id
}

resource "aws_network_acl" "cyber94_calculator_oabu_nacl_public_tf" {
  vpc_id = aws_vpc.cyber94_calculator_oabu_vpc_tf.id

  ingress {
    protocol = "tcp"
    rule_no = 100
    from_port = 22
    to_port = 22
    cidr_block = "0.0.0.0/0"
    action = "allow"
  }

  ingress {
    protocol = "tcp"
    rule_no = 200
    from_port = 443
    to_port = 443
    cidr_block = "0.0.0.0/0"
    action = "allow"
  }

  ingress {
    protocol = "tcp"
    rule_no = 1000
    from_port = 1024
    to_port = 65535
    cidr_block = "0.0.0.0/0"
    action = "allow"
  }

  egress {
    protocol = "tcp"
    rule_no = 100
    from_port = 80
    to_port = 80
    cidr_block = "0.0.0.0/0"
    action = "allow"
  }

  egress {
    protocol = "tcp"
    rule_no = 200
    from_port = 443
    to_port = 443
    cidr_block = "0.0.0.0/0"
    action = "allow"
  }

  egress {
    protocol = "tcp"
    rule_no = 1000
    from_port = 1024
    to_port = 65535
    cidr_block = "0.0.0.0/0"
    action = "allow"
  }

  subnet_ids = [aws_subnet.cyber94_calculator_oabu_subnet_public_tf.id]

  tags = {
    Name = "cyber94_calculator_oabu_nacl_public"
  }
}

resource "aws_security_group" "cyber94_calculator_oabu_sg_server_public_tf" {
  name = "cyber94_calculator_oabu_sg_server_public"

  vpc_id = aws_vpc.cyber94_calculator_oabu_vpc_tf.id

  ingress {
    from_port =  22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port =  443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cyber94_calculator_oabu_sg_server_public"
  }
}

# @component CalcApp:Web:Server (#web_server)
# @connects #subnet to #web_server with Network
resource "aws_instance" "cyber94_calculator_oabu_server_public_tf" {
  ami = "ami-0943382e114f188e8"
  instance_type = "t2.micro"
  key_name = "cyber-oabu-key"
  associate_public_ip_address = true
  subnet_id = aws_subnet.cyber94_calculator_oabu_subnet_public_tf.id

  vpc_security_group_ids = [aws_security_group.cyber94_calculator_oabu_sg_server_public_tf.id]
  count = 1

  tags = {
    Name = "cyber94_calculator_oabu_server_public"
  }

  lifecycle {
    create_before_destroy = true
  }


  # Just to make sure that terraform will not contrinue to local-exec before the server is up
  connection {
      type = "ssh"
      user = "ubuntu"
      host = self.public_ip
      private_key = file("/home/kali/.ssh/cyber-oabu-key.pem")
  }

  # Just to make sure that terraform will not contrinue to local-exec before the server is up
  provisioner "remote-exec" {
    inline = [
      "pwd"
    ]
  }

  # To provision the server using ansible playbook
  provisioner "local-exec" {
    working_dir = "../ansible"
    command = "ansible-playbook -i ${self.public_ip}, -u ubuntu provisioner.yml"
  }

  /*
  # This section is to provision the server to install docker from terraform directly
  connection {
      type = "ssh"
      user = "ubuntu"
      host = self.public_ip
      private_key = file("/home/kali/.ssh/cyber-oabu-key.pem")
  }

  provisioner "file" {
      source = "../init-scripts/docker-install.sh"
      destination = "/home/ubuntu/docker-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 777 /home/ubuntu/docker-install.sh",
      "/home/ubuntu/docker-install.sh"
    ]
  }
  */
}
