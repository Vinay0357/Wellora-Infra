project_name               = "wellora"
environment                = "dev"
aws_region                 = "ap-southeast-2"
vpc_id                     = "vpc-0e07ade0dcf9ca967"
app_tier_security_group_id = "sg-078b25d442a05949f"
private_subnet_ids         = ["subnet-02cc6564a19c49455", "subnet-0e20e352b11a6f383", "subnet-008d7e60f876ce189"]
private_route_table_ids    = ["rtb-03c16a5a011155e6f", "rtb-0fa18e44c8ebbf149", "rtb-058fca9356527e35b"]

create_transcribe_interface_endpoint = true
create_bedrock_interface_endpoint = true
create_healthlake_interface_endpoint = true
create_ecr_interface_endpoints = true
create_logs_interface_endpoint = true
create_ssm_interface_endpoints = true
