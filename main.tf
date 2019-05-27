provider "aws" {
  region  = var.aws_region
}

module "prereqs" {
  source        = "./modules/prereqs"
  aws_region    = var.aws_region
  name_prefix   = var.name_prefix
  name_suffix   = var.name_suffix
  environment   = var.environment
  aws_account   = var.aws_account
  subscriptions = var.subscriptions
}

module "iam" {
  source        = "./modules/iam"
  aws_region    = var.aws_region
  name_prefix   = var.name_prefix
  name_suffix   = var.name_suffix
  environment   = var.environment
  aws_account   = var.aws_account
  subscriptions = var.subscriptions
}

module "approval" {
  source   = "./modules/approval"
  approval = "False"
}

module "WithApprovalStage" {
  source          = "./modules/codepipeline/Approval"
  approval        = module.approval.approval
  aws_region      = var.aws_region
  name_prefix     = var.name_prefix
  name_suffix     = var.name_suffix
  environment     = var.environment
  aws_account     = var.aws_account
  role_arn        = module.iam.role_arn
  subscriptions   = var.subscriptions
  tflambda_bucket = module.prereqs.tflambda_bucket
}

module "NoApprovalStage" {
  source          = "./modules/codepipeline/NoApproval"
  approval        = module.approval.approval
  aws_region      = var.aws_region
  name_prefix     = var.name_prefix
  name_suffix     = var.name_suffix
  environment     = var.environment
  aws_account     = var.aws_account
  role_arn        = module.iam.role_arn
  tflambda_bucket = module.prereqs.tflambda_bucket
}
