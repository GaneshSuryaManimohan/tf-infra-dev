locals {
  # this will select the first public subnet from the comma-separated list
  public_subnet_id = split(",", data.aws_ssm_parameter.public_subnet_ids.value)[0]
}