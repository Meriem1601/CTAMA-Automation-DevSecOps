# Variables
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
  default = "eu-north-1"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu Server 22.04 LTS (64-bit x86)"
  default     = "ami-07a0715df72e58928"
}

variable "key_name1" {}
variable "key_name2" {}
variable "key_name3" {}

variable "private_key_path1" {}
variable "private_key_path2" {}
variable "private_key_path3" {}

# Providers
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

# Resources
# Default VPC, it won't delete on destroy
resource "aws_default_vpc" "default" {}

resource "aws_security_group" "allow_all_traffic" {
  name        = "allow_all_traffic"
  description = "Allow all inbound and outbound traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k8s_instances" {
  count                  = 3
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  key_name               = lookup({
    0 = var.key_name1
    1 = var.key_name2
    2 = var.key_name3
  }, count.index)
  vpc_security_group_ids = [aws_security_group.allow_all_traffic.id]
  tags = {
    Name = lookup({
      0 = "k8s-master"
      1 = "k8s-slave1"
      2 = "k8s-slave2"
    }, count.index)
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file(lookup({
      0 = var.private_key_path1
      1 = var.private_key_path2
      2 = var.private_key_path3
    }, count.index))
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install nginx -y",
      "sudo systemctl start nginx"
    ]
  }
}

# Outputs
output "instance_details" {
  value = [for instance in aws_instance.k8s_instances : {
    name       = instance.tags.Name
    public_dns = instance.public_dns
    public_ip  = instance.public_ip
    private_ip = instance.private_ip
  }]
}
