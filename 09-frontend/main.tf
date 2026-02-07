module "frontend_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws" # using EC2 instance module
  name = "${var.project_name}-${var.environment}-frontend"
  instance_type = "t3.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.frontend_sg_id.value]
  subnet_id = local.public_subnet_id
  ami = data.aws_ami.ami_info.id
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-frontend"
    }
  )
}

# Uses a null_resource with SSH provisioners to copy and execute the frontend setup script on the EC2 instance, and re-runs only when the frontend instance is replaced
resource "null_resource" "frontend_setup" {
  triggers = {
    frontend_instance_id = module.frontend_instance.id #this will trigger recreation if frontend instance changes
  }
  connection {
    type = "ssh"
    user = "ec2-user"
    password = "DevOps321"
    host = module.frontend_instance.private_ip # connect via private IP
  }
  provisioner "file" {
    source = "frontend.sh"
    destination = "/tmp/frontend.sh"
  }
  provisioner "remote-exec" {
    inline = [ 
      "chmod +x /tmp/frontend.sh", # make the script executable
      "sudo bash /tmp/frontend.sh ${var.common_tags.Component} ${var.environment}" # execute the script with component and environment as arguments
     ]
  }
}

# Stops the frontend EC2 instance after provisioning completes to ensure setup runs only once
resource "aws_ec2_instance_state" "frontend_instance" {
  instance_id = module.frontend_instance.id
  state = "stopped"
  depends_on = [ null_resource.frontend_setup ]
}

# Create a reusable AMI from the frontend EC2 instance after it has been cleanly stopped
resource "aws_ami_from_instance" "frontend_instance" {
  name = "${var.project_name}-${var.environment}-frontend"
  source_instance_id = module.frontend_instance.id
  depends_on = [ aws_ec2_instance_state.frontend_instance ]
}

# Terminates the frontend EC2 instance via AWS CLI after the AMI has been successfully created
resource "null_resource" "frontend_delete" {
  triggers = {
    instance_id = module.frontend_instance.id
  }
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${module.frontend_instance.id}"
  }
  depends_on = [ aws_ami_from_instance.frontend_instance ]
}

# Defines an ALB target group for the frontend service with HTTP health checks on /health
resource "aws_lb_target_group" "frontend" {
  name = "${var.project_name}-${var.environment}-${var.common_tags.Component}"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  health_check {
    path = "/"
    port = 80
    protocol = "HTTP"
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200-209"
  }
}

# Defines a launch template for frontend EC2 instances using the custom AMI and standard instance configuration
resource "aws_launch_template" "frontend" {
  name = "${var.project_name}-${var.environment}-frontend"
  image_id = aws_ami_from_instance.frontend_instance.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t3.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.frontend_sg_id.value]
  update_default_version = true #sets the latest version to default
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
      Name = "${var.project_name}-${var.environment}-frontend"
      }
    )
  }
}

# Manages frontend EC2 instances using an Auto Scaling Group with rolling updates triggered by launch template changes
resource "aws_autoscaling_group" "frontend" {
  name = "${var.project_name}-${var.environment}-frontend"
  max_size = 5
  min_size = 1
  health_check_grace_period = 60
  health_check_type = "ELB"
  desired_capacity = 1
  target_group_arns = [aws_lb_target_group.frontend.arn]
  launch_template {
    id = aws_launch_template.frontend.id
    version = "$Latest"
  }
  vpc_zone_identifier = split(",", data.aws_ssm_parameter.public_subnet_ids.value)
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  tag {
    key = "Name"
    value = "${var.project_name}-${var.environment}-frontend"
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

# Configures target-tracking scaling for the frontend ASG based on average CPU utilization
resource "aws_autoscaling_policy" "frontend" {
  name = "${var.project_name}-${var.environment}-frontend"
  policy_type = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 10.0
  }
}


resource "aws_lb_listener_rule" "frontend" {
  listener_arn = data.aws_ssm_parameter.web_alb_listener_arn_https.value
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = ["web-${var.environment}.${var.zone_name}"]
    }
  }
}
