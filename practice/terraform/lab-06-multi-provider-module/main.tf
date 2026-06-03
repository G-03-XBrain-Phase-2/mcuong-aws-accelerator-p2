# Default AWS Provider (Singapore)
provider "aws" {
  region     = var.aws_region_sg
  access_key = var.access_key
  secret_key = var.secret_key
  token      = var.session_token
}

# Alias AWS Provider (US East - N. Virginia)
provider "aws" {
  alias      = "us_east"
  region     = var.aws_region_us
  access_key = var.access_key
  secret_key = var.secret_key
  token      = var.session_token
}

# Deploy EC2 in Singapore (Using Default Provider)
module "ec2_singapore" {
  source        = "./modules/simple-ec2"
  ami           = var.ami_sg
  instance_type = "t3.micro"
  instance_name = "cuong-sg-instance"
  subnet_id     = var.subnet_id_sg
}

# Deploy EC2 in US East (Using US East Provider Alias)
module "ec2_us_east" {
  source        = "./modules/simple-ec2"
  ami           = var.ami_us
  instance_type = "t2.micro" # t2.micro is default eligible in us-east-1
  instance_name = "cuong-us-instance"
  subnet_id     = var.subnet_id_us

  providers = {
    aws = aws.us_east
  }
}
