module "backend_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws" # using EC2 instance module
  name = "${var.project_name}-${var.environment}-backend"
  instance_type = "t3.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.backend_sg_id.value]
  subnet_id = local.private_subnet_id
  ami = data.aws_ami.ami_info.id
  user_data = file("backend.sh")
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-backend"
    }
  )
}

resource "null_resource" "backend_setup" {
  triggers = {
    backend_instance_id = module.backend_instance.id #this will trigger recreation if backend instance changes
  }
  connection {
    type = "ssh"
    user = "ec2-user"
    password = "DevOps321"
    host = module.backend_instance.private_ip # connect via private IP
  }
  provisioner "file" {
    source = "backend.sh"
    destination = "/tmp/backend.sh"
  }
  provisioner "remote-exec" {
    inline = [ 
      "chmod +x /tmp/${var.common_tags.Component}.sh", # make the script executable
      "sudo sh /tmp/${var.common_tags.Component}.sh ${var.common_tags.Component} ${var.environment}" # execute the script with component and environment as arguments
     ]
  }
}