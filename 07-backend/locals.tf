locals {
  # this will select the first public subnet from the comma-separated list
  private_subnet_id = split(",", data.aws_ssm_parameter.private_subnet_ids.value)[0]
}