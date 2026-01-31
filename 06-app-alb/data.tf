data "aws_ssm_parameter" "alb_sg_id" {
  name = "/${var.project_name}/${var.environment}/alb_sg_id"  
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/${var.project_name}/${var.environment}/private_subnet_ids"
}

data "aws_route53_zone" "existing" {
  name         = var.zone_name
  private_zone = false
}

data "aws_ami" "ami_info" {
  most_recent = true
  owners      = ["679593333241"] # Amazon Linux AMI Owner ID

  filter {
    name   = "name"
    values = ["OpenVPN Access Server Community Image-fe8020db-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}