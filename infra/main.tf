# variables
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "key_name" {}
variable "private_key_path" {}
variable "region" {
    default = "eu-north-1"
}

# Providers
provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region     = var.region
}

# DATA
data "aws_ami" "aws_linux" {
    most_recent = true
    owners      = ["amazon"]
    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name   = "root-device-type"
        values = ["ebs"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

# RESOURCES
# Default VPC, it won't delete on destroy
resource "aws_default_vpc" "default" {}

resource "aws_security_group" "allow_ssh_http_80" {
    name        = "allow_ssh_http"
    description = "Allow ssh on 22 & http on port 80"
    vpc_id      = aws_default_vpc.default.id
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "nginx" {
    count                  = 3
    ami                    = data.aws_ami.aws_linux.id
    instance_type          = "t3.micro"
    key_name               = var.key_name
    vpc_security_group_ids = [aws_security_group.allow_ssh_http_80.id]

    connection {
        type        = "ssh"
        host        = self.public_ip
        user        = "ec2-user"
        private_key = file(var.private_key_path)
    }

    provisioner "remote-exec" {
        inline = [
            "sudo amazon-linux-extras install nginx1 -y",
            "sudo systemctl start nginx"
        ]
    }
}

# OUTPUT
output "aws_instance_public_dns" {
    value = [for instance in aws_instance.nginx : instance.public_dns]
}
