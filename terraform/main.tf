# Provider de AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
}

# Variables
variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

# Data source to get IAM role
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}


resource "aws_vpc" "demo-vpc" {
  cidr_block           = "10.0.0.0/16"

  tags = {
    Name = "demo-vpc"
  }
}

resource "aws_subnet" "demo-subnet-1" {
  vpc_id                  = aws_vpc.demo-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "demo-subnet-1"
  }
}

resource "aws_subnet" "demo-subnet-2" {
  vpc_id                  = aws_vpc.demo-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "demo-subnet-2"
  }
}


resource "aws_eks_cluster" "demo-eks" {
  name = "demo-eks"
  access_config {
    authentication_mode = "API"
  }
  role_arn = data.aws_iam_role.lab_role.arn
  version  = "1.31"
  vpc_config {
    subnet_ids = [aws_subnet.demo-subnet-1.id, aws_subnet.demo-subnet-2.id]
  }
}

resource "aws_eks_node_group" "demo-node-group" {
  cluster_name = aws_eks_cluster.demo-eks.name
  node_group_name = "demo-node-group"
  node_role_arn = data.aws_iam_role.lab_role.arn
  subnet_ids = [aws_subnet.demo-subnet-1.id, aws_subnet.demo-subnet-2.id]
  instance_types = ["t3.medium"]
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  tags = {
    Name = "demo-node-group"
  }
}

resource "aws_ecr_repository" "demo-ecr" {
  name                 = "demo-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "demo-ecr"
  }
}
