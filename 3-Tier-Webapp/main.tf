# configure aws provider
provider "aws"{
    region      = var.region
    access_key  = "AccessKey"            #Add a valid access key
    secret_key  = "SecretKey"            #Add a valid secret key             
}

# create vpc
module "vpc"{
    source                              = "../modules/vpc"
    region                              = var.region
    project_name                        = var.project_name
    vpc_cidr                            = var.vpc_cidr
    public_subnet_az1_cidr              = var.public_subnet_az1_cidr
    public_subnet_az2_cidr              = var.public_subnet_az2_cidr
    private_app_subnet_az1_cidr         = var.private_app_subnet_az1_cidr
    private_app_subnet_az2_cidr         = var.private_app_subnet_az2_cidr
    private_database_subnet_az1_cidr    = var.private_database_subnet_az1_cidr
    private_database_subnet_az2_cidr    = var.private_database_subnet_az2_cidr
}

# create Security Groups
module "SecurityGroups" {
  source                                = "../modules/SecurityGroups"
  vpc_id                                = module.vpc.vpc_id
  depends_on                            = [ module.vpc ]
}

# create RDS Instance
module "RDS" {
  source                            = "../modules/RDS"
  private_database_subnet_az1_id    = module.vpc.private_database_subnet_az1_id
  private_database_subnet_az2_id    = module.vpc.private_database_subnet_az2_id
  database_securitygroup_id         = module.SecurityGroups.database_securitygroup_id
  depends_on                        = [ module.SecurityGroups, module.vpc, ]
}

# create Launch Template, ASG
module "LaunchTemplate"{
    source                          = "../modules/LaunchTemplate"
    region                          = var.region
    project_name                    = var.project_name
    vpc_id                          = module.vpc.vpc_id
    public_subnet_az1_id            = module.vpc.public_subnet_az1_id
    public_subnet_az2_id            = module.vpc.public_subnet_az2_id
    private_app_subnet_az1_id       = module.vpc.private_app_subnet_az1_id
    private_app_subnet_az2_id       = module.vpc.private_app_subnet_az2_id
    private_database_subnet_az1_id  = module.vpc.private_database_subnet_az1_id
    private_database_subnet_az2_id  = module.vpc.private_database_subnet_az2_id
    web_securitygroup_id            = module.SecurityGroups.web_securitygroup_id
    app_securitygroup_id            = module.SecurityGroups.app_securitygroup_id
    depends_on                      = [ module.RDS ]
}
