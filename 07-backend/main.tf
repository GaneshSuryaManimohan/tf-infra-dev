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

resource "aws_ec2_instance_state" "backend_instance" {
  instance_id = module.backend_instance.id
  state = "stopped"
  depends_on = [ null_resource.backend_setup ] #this stops the server when null resource provisioning is completed
}

resource "aws_ami_from_instance" "backend_instance" {
  name = "${var.project_name}-${var.environment}-backend"
  source_instance_id = module.backend_instance.id
  depends_on = [ aws_ec2_instance_state.backend_instance ]
}

resource "null_resource" "backend_delete" {
  triggers = {
    instance_id = module.backend_instance.id
  }
  connection {
    type = "ssh"
    user = "ec2-user"
    password = "DevOps321"
    host = module.backend_instance.private_ip
  }
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${module.backend_instance.id}"
  }
  depends_on = [ aws_ami_from_instance.backend_instance ]
}

resource "aws_lb_target_group" "backend" {
  name = "${var.project_name}-${var.environment}-${var.common_tags.Component}"
  port = 8080
  protocol = "HTTP"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  health_check {
    path = "/health"
    port = 8080
    protocol = "HTTP"
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200"
  }
}

resource "aws_launch_template" "backend" {
  name = "${var.project_name}-${var.environment}-backend"
  image_id = aws_ami_from_instance.backend_instance.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t3.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.backend_sg_id.value]
  update_default_version = true #sets the latest version to default
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
      Name = "${var.project_name}-${var.environment}-backend"
      }
    )
  }
}

resource "aws_autoscaling_group" "backend" {
  name = "${var.project_name}-${var.environment}-backend"
  max_size = 5
  min_size = 1
  health_check_grace_period = 60
  health_check_type = "ELB"
  desired_capacity = 1
  launch_template {
    id = aws_launch_template.backend.id
    version = "$Latest"
  }
  vpc_zone_identifier = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  tag {
    key = "Name"
    value = "${var.project_name}-${var.environment}-backend"
    propagate_at_launch = true
  }
  timeouts {
    delete = "15m"
  }

  tag {
    key = "Project"
    value = "${var.project_name}"
    propagate_at_launch = false
  }
}