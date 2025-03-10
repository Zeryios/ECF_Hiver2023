variable "region" {}
variable "cluster_name" {}
variable "db_host" {}
variable "db_port" { default = "3306" }
variable "db_user" {}
variable "db_password" {}
variable "db_name" {}
variable "docker_username" {}
variable "docker_password" {}
variable "docker_email" {}
variable "app_image"{}
variable "ssh_key_name"{}
variable "vpc_id"{}
variable "public_subnet_id" {}