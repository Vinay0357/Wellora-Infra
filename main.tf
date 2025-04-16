terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Specify a compatible AWS provider version
    }
  }
  # Add backend configuration here (recommended)
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket-name"
  #   key    = "wellora/prod/networking/terraform.tfstate" # Example key
  #   region = "ap-southeast-2"
  #   dynamodb_table = "your-terraform-lock-table" # Optional: for state locking
  # }
}

provider "aws" {
  region = var.aws_region # Use region defined in root variables.tf
}

# --- Call the Networking Module ---
module "networking" {
  source = "./modules/01_networking" # Path to the module

  # Pass required variables (or rely on defaults if suitable)
  aws_region      = var.aws_region
  project_name    = var.project_name
  environment     = var.environment
  availability_zones = []
  # vpc_cidr        = "10.98.0.0/16" # Can override defaults if needed
  # availability_zones = var.availability_zones # Pass specific AZs if defined

  # Example of passing common tags
  # common_tags = {
  #   Owner = "DevTeam"
  #   CostCenter = "12345"
  # }

  # Keep NAT Gateway enabled (default)
  # enable_nat_gateway = true
  # Use one NAT Gateway per AZ (default)
  # single_nat_gateway = false
}

# --- Call the Security Groups Module ---
module "security_groups" {
  source = "./modules/02_security_groups" # Path to the module

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id # Get VPC ID from the networking module output

  # Customize ports if needed (defaults are 80/443 for ALB, 8080 for App, 5432 for DB)
  # app_port = 80
  # db_port  = 3306 # Example for MySQL

  # IMPORTANT: Populate admin_access_cidrs - ideally from a VPN module output later,
  # or temporarily hardcode your IP (e.g., ["YOUR_IP/32"]) - NOT recommended for prod.
  # Example using a variable defined in the root module:
  # admin_access_cidrs = var.vpn_cidr_blocks

  # Pass common tags if needed
  # common_tags = { ... }
}

# --- Call the VPC Endpoints Module ---
module "vpc_endpoints" {
  source = "./modules/03_vpc_endpoints" # Path to the module

  project_name    = var.project_name
  environment     = var.environment
  aws_region      = var.aws_region
  vpc_id          = module.networking.vpc_id
  app_tier_security_group_id = module.security_groups.app_security_group_id

  # Pass the appropriate subnet IDs (usually private app subnets)
  private_subnet_ids = module.networking.private_app_subnet_ids

  # Pass the private route table IDs for Gateway Endpoints
  private_route_table_ids = module.networking.private_route_table_ids

  # --- Enable/Disable Endpoints as needed ---
  create_s3_gateway_endpoint         = true
  create_dynamodb_gateway_endpoint   = true
  create_transcribe_interface_endpoint = true
  create_bedrock_interface_endpoint  = true # Verify exact service name if needed
  create_healthlake_interface_endpoint = true
  create_ecr_interface_endpoints     = true # Essential for EKS/ECS in private subnets
  create_logs_interface_endpoint     = true # Recommended for private instances
  create_ssm_interface_endpoints     = true # Recommended for management

  # Pass common tags if needed
  # common_tags = { ... }
}

# --- Call the IAM Module ---
module "iam" {
  source = "./modules/04_iam" # Path to the module

  project_name = var.project_name
  environment  = var.environment

  # --- EKS / IRSA Specific ---
  create_eks_roles = true # Assuming EKS is used
  # These should come from your EKS module outputs if using IRSA
  # oidc_provider_arn = module.eks.oidc_provider_arn # Example
  # oidc_provider_url = module.eks.oidc_provider_url # Example

  # --- Application Permissions ---
  create_app_task_role = true
  # Pass ARNs of resources created in other modules
  # s3_general_bucket_arns = [module.s3.raw_audio_bucket_arn, module.s3.transcripts_bucket_arn] # Example
  # s3_static_assets_bucket_arn = module.s3.static_assets_bucket_arn # Example
  # dynamodb_table_arns = [module.persistence.app_data_table_arn] # Example
  # kms_key_arns_for_encryption = [module.kms.data_key_arn] # Example

  # --- Node Configuration ---
  attach_ssm_policy_to_nodes = true
  attach_cloudwatch_agent_policy_to_nodes = false # Enable if needed

  # --- Common Tags ---
  # common_tags = { ... }
}

# --- Call the S3 Module ---
module "s3" {
  source = "./modules/05_s3" # Path to the module

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # --- Configuration ---
  enable_versioning     = true
  enable_access_logging = true
  # create_access_log_bucket = true # Default
  # access_log_bucket_name_suffix = "s3-logs" # Example override

  encryption_type = "AES256" # Or "aws:kms"
  # kms_key_arn     = module.kms.key_arn # Provide if using SSE-KMS

  # Lifecycle rules - enabled by default
  # ia_transition_days = 60 # Example override

  # Static Assets specific
  static_assets_block_public_access = true # Keep true, use CloudFront OAI/OAC
  # enable_cors_static_assets = true # If needed
  # cors_allowed_origins = ["https://your-app-domain.com"] # Example

  # Use force_destroy ONLY in non-production environments if needed for cleanup
  # force_destroy_buckets = true

  # Pass common tags if needed
  # common_tags = { ... }

  # --- Dependencies ---
  # No explicit dependencies needed here unless using KMS key from another module for encryption
}

# --- Call the Persistence Module ---
module "persistence" {
  source = "./modules/06_persistence" # Path to the module

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  db_password = ""

  # Subnets and Security Groups
  db_subnet_ids        = module.networking.private_db_subnet_ids
  db_security_group_id = [module.security_groups.db_security_group_id] # Pass as list

  # --- RDS Config ---
  create_rds = true
  # db_instance_class = "db.t3.small" # Override defaults if needed
  # db_engine_version = "15.5" # Example override
  # IMPORTANT: Provide password securely! E.g. set TF_VAR_db_password environment variable
  # db_password = var.db_password # Assumes root var `db_password` defined and sourced securely

  # --- ElastiCache Config ---
  create_elasticache_redis = true
  # elasticache_node_type = "cache.t3.small" # Override defaults if needed

  # --- DynamoDB Config ---
  create_dynamodb_tables = true
  # dynamodb_tables = { ... } # Override default table definition if needed

  # --- KMS Keys (Optional) ---
  # rds_kms_key_arn = module.kms.key_arn # Example if using KMS module
  # elasticache_kms_key_arn = module.kms.key_arn # Example
  # dynamodb_tables = { ... kms_key_arn = module.kms.key_arn ... } # Example

  # --- Common Tags ---
  # common_tags = { ... }

  # Explicit dependency on Security Group module might be good practice
  depends_on = [
    module.security_groups
  ]
}

# --- Call the Compute (EKS/ECR) Module ---
module "compute" {
  source = "./modules/07_compute" # Path to the module

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  vpc_id       = module.networking.vpc_id

  # Subnets for EKS
  private_subnet_ids = module.networking.private_app_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids # Needed if public endpoint enabled or using public nodes

  # IAM Roles from IAM Module
  eks_cluster_role_arn = module.iam.eks_cluster_role_arn
  eks_node_role_arn    = module.iam.eks_node_role_arn

  # EKS Cluster Config
  # cluster_name = "wellora-prod-cluster" # Override default name if desired
  # cluster_version = "1.28" # Override default version if needed
  # cluster_endpoint_public_access_cidrs = ["YOUR_CORP_IP/32", "YOUR_HOME_IP/32"] # Restrict public access

  # EKS Node Group Config
  # nodegroup_instance_types = ["m5.large"] # Override default instance type
  # nodegroup_scaling_desired_size = 3 # Override default scaling

  # ECR Config
  create_ecr_repos = true
  # ecr_repository_names = ["app-frontend", "app-backend"] # Override default repo names

  # Common Tags
  # common_tags = { ... }

  # Explicit dependency on IAM module
  depends_on = [
    module.iam
  ]
}

# --- Retrieve ACM Certificate ---
# It's recommended to manage the ACM certificate outside this core infra,
# or use a data source if it already exists.
data "aws_acm_certificate" "cert" {
  # Domain name must match the certificate you created in ACM
  domain   = var.domain_name # Define var.domain_name in root variables
  statuses = ["ISSUED"]
  # most_recent = true # Uncomment if multiple certs match
}

# --- Call the Load Balancing Module ---
module "load_balancing" {
  source = "./modules/08_load_balancing" # Path to the module

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id

  # Subnets and Security Groups
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = [module.security_groups.alb_security_group_id] # Pass as list

  # Target Group Config (ensure port matches app)
  # target_group_port = 8080 # Override default if needed

  # Listeners Config
  enable_https_listener = true
  acm_certificate_arn   = data.aws_acm_certificate.cert.arn # Pass the certificate ARN
  # http_to_https_redirect = true # Default

  # Access Logs Config
  enable_alb_access_logs     = true
  # Ensure S3 module output provides the log bucket name, or define it here
  access_logs_s3_bucket_name = module.s3.access_log_bucket_id # Example using S3 module output
  # access_logs_s3_prefix = "wellora-alb-logs" # Override default prefix if needed

  # Common Tags
  # common_tags = { ... }

  depends_on = [
    module.security_groups,
    module.s3 # If referencing S3 log bucket output
  ]
}

# --- Call the Edge (CloudFront/WAF) Module ---
module "edge" {
  source = "./modules/09_edge" # Path to the module

  project_name = var.project_name
  environment  = var.environment

  # Origins
  alb_dns_name                             = module.load_balancing.alb_dns_name
  s3_static_assets_bucket_regional_domain_name = module.s3.static_assets_bucket_regional_domain_name
  s3_static_assets_bucket_id               = module.s3.static_assets_bucket_id

  # Distribution Settings
  domain_aliases                 = [var.domain_name] # Pass domain name(s)
  cloudfront_acm_certificate_arn = var.cloudfront_acm_cert_arn_us_east_1 # Pass cert ARN

  # WAF
  enable_waf      = true # Or false
  waf_web_acl_arn = var.waf_acl_arn_us_east_1 # Pass WAF ARN

  # Logging
  enable_cloudfront_logging = true
  log_bucket_name           = module.s3.access_log_bucket_id # Use log bucket from S3 module

  # Cache Policies (use defaults or provide custom IDs)
  # static_assets_cache_policy_id = "..."
  # api_cache_policy_id = "..."
  # api_origin_request_policy_id = "..."

  # Common Tags
  # common_tags = { ... }

  depends_on = [
    module.load_balancing,
    module.s3
  ]
}


# --- Example Route53 Record ---
# resource "aws_route53_record" "app_alias" {
#   zone_id = data.aws_route53_zone.primary.zone_id # Assumes data source gets your hosted zone ID
#   name    = var.domain_name
#   type    = "A"
#
#   alias {
#     name                   = module.edge.cloudfront_distribution_domain_name
#     zone_id                = module.edge.cloudfront_distribution_hosted_zone_id
#     evaluate_target_health = false
#   }
# }

# --- Call the Authentication (Cognito) Module ---
module "authentication" {
  source = "./modules/10_authentication" # Path to the module

  project_name = var.project_name
  environment  = var.environment

  # --- Pool Config ---
  # user_pool_name = "wellora-app-users" # Override default if needed
  mfa_configuration = "OPTIONAL"
  # password_policy_minimum_length = 10 # Override default if needed

  # --- Client Config ---
  # client_name = "web-client" # Override default if needed
  # generate_client_secret = false # Default is false (good for SPAs)
  allowed_oauth_flows = ["code"] # Ensure PKCE is used in your frontend app
  allowed_oauth_scopes = ["openid", "email", "profile", "phone"]
  # IMPORTANT: Replace localhost URLs with your actual deployed frontend URLs
  callback_urls = ["https://app.wellora.com/callback", "http://localhost:3000/callback"] # Example
  logout_urls   = ["https://app.wellora.com/logout", "http://localhost:3000/logout"]   # Example

  # --- Domain (Optional) ---
  # create_user_pool_domain = true # Set true if using Cognito Hosted UI
  # user_pool_domain_prefix = "wellora-prod-auth" # Must be globally unique

  # --- Tags ---
  # common_tags = { ... }
}

# --- Call the Messaging (SNS/SES) Module ---
module "messaging" {
  source = "./modules/11_messaging" # Path to the module

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # --- SES Config ---
  enable_ses      = true
  # Provide the domain you want to verify for sending emails
  ses_domain_name = var.ses_sending_domain # Define var.ses_sending_domain in root variables

  # --- SNS Config ---
  enable_sns      = true
  sns_topic_names = ["AppEvents", "Alerts", "TranscriptionResults"] # Override default topic names if needed
  # sns_kms_master_key_arn = module.kms.key_arn # Optional: Encrypt with a specific CMK

  # --- Tags ---
  # common_tags = { ... }
}

# --- Call the AI Services (HealthLake) Module ---
module "ai_services" {
  source = "./modules/12_ai_services" # Path to the module

  project_name = var.project_name
  environment  = var.environment

  create_healthlake_datastore = true # Create the datastore as shown in diagram

  # healthlake_datastore_name = "wellora-main-fhir" # Override default name if needed
  # healthlake_datastore_type_version = "R4" # Default is R4

  # Optional: Encrypt with a specific KMS key
  # healthlake_sse_kms_key_arn = module.kms.key_arn # Example if using KMS module

  # Optional: Preload Synthea data
  # healthlake_preload_data_config = {
  #   preload_data_type = "SYNTHEA"
  # }

  # Common Tags
  # common_tags = { ... }
}

# --- Call the Security & Compliance Module ---
module "security_compliance" {
  source = "./modules/13_security_compliance" # Path to the module

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # --- Service Enables ---
  enable_guardduty    = true
  enable_config       = true
  enable_cloudtrail   = true
  enable_security_hub = true
  enable_inspector    = true
  enable_macie        = true

  # --- Service Configurations ---

  # Provide S3 bucket name from S3 module output (assuming a dedicated log bucket was created)
  config_s3_bucket_name     = module.s3.access_log_bucket_id # Example
  config_s3_key_prefix      = "aws-config"                   # Example prefix
  # config_sns_topic_arn   = module.messaging.sns_topic_arns["ConfigNotifications"] # Example

  cloudtrail_s3_bucket_name = module.s3.access_log_bucket_id # Example
  cloudtrail_s3_key_prefix  = "aws-cloudtrail"               # Example prefix
  # cloudtrail_kms_key_arn = module.kms.cloudtrail_key_arn # Optional

  # security_hub_enable_default_standards = true # Default

  # inspector_scan_lambda = true # Enable Lambda scanning if needed

  # macie_enable_automated_discovery = true # Enable if desired

  # --- Common Tags ---
  # common_tags = { ... }

  depends_on = [
    module.s3, # If using S3 bucket outputs
    module.messaging # If using SNS topic output
  ]
}

# --- Define Security Group for VPN Endpoint (Optional - Create or use existing) ---
# resource "aws_security_group" "vpn_endpoint_sg" {
#   name        = "${var.project_name}-${var.environment}-vpn-endpoint-sg"
#   description = "Allow outbound traffic from VPN clients"
#   vpc_id      = module.networking.vpc_id
#   egress { ... allow necessary outbound ... }
#   tags = { Name = "${var.project_name}-${var.environment}-vpn-endpoint-sg" }
# }

# --- Call the Admin Access (Client VPN) Module ---
module "admin_access" {
  source = "./modules/14_admin_access" # Path to the module

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id

  # Associate with appropriate private subnets (needs >= 2 in different AZs)
  vpn_target_subnet_ids = module.networking.private_app_subnet_ids

  # Assign a security group to the VPN ENIs
  vpn_endpoint_security_group_ids = [aws_security_group.default[0].id] # Example: using default SG - Review This! Or use custom SG like vpn_endpoint_sg above

  # VPN Config
  client_cidr_block      = "10.99.0.0/16" # Ensure this doesn't overlap!
  server_certificate_arn = var.vpn_server_cert_arn
  client_certificate_arn = var.vpn_client_cert_arn # Required for certificate-authentication
  # authentication_type = "certificate-authentication" # Default

  # Authorization
  authorize_all_users_to_vpc = true
  vpc_cidr_for_authorization = module.networking.vpc_cidr_block

  # Logging
  enable_connection_logging = true

  # Common Tags
  # common_tags = { ... }

  depends_on = [
    module.networking
  ]
}

# --- IMPORTANT REMINDER ---
# You MUST update Security Groups (e.g., in modules/02_security_groups)
# to allow ingress traffic FROM the `module.admin_access.client_cidr_block` output
# on the necessary ports (e.g., 22 for SSH, 3389 for RDP, 443 for HTTPS)
# to the target resources (e.g., App Tier SG, DB Tier SG).
# Example update in modules/02_security_groups/main.tf within aws_security_group.app:
# ingress {
#   description = "Allow SSH from VPN Client CIDR"
#   from_port   = 22
#   to_port     = 22
#   protocol    = "tcp"
#   cidr_blocks = [var.vpn_client_cidr] # Need to add vpn_client_cidr variable to SG module
# }