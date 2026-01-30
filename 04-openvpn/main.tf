# Create a key pair for vpn instance
resource "aws_key_pair" "vpn" {
  public_key = file(var.public_key_path)
}

# Create a vpn EC2 instance using the terraform-aws-modules/ec2-instance/aws module
module "vpn_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws" # using EC2 instance module
  name = "${var.project_name}-${var.environment}-vpn"
  instance_type = "t3.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.vpn_sg_id.value]
  subnet_id = local.public_subnet_id
  ami = data.aws_ami.ami_info.id
  user_data = file("vpn.sh")
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-vpn"
    }
  )
}