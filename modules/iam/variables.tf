variable "name_prefix" {
  type = "string"
}

variable "name_suffix" {
  type = "string"
}

variable "environment" {
  type = "string"
}

variable "aws_region" {
  type = "string"
}

variable "aws_account" {
  type = "string"
}

variable "subscriptions" {
  description = "List of telephone numbers to subscribe to SNS."
  type        = "list"
}