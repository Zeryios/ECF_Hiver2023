# Provider AWS pour récupérer des informations sur le cluster EKS
provider "aws" {
  region = var.region  # Utilise la variable 'region' définie dans le fichier .tfvars
}

# Récupérer les informations sur votre cluster EKS
data "aws_eks_cluster" "eks_cluster" {
  name = var.cluster_name  # Utilise la variable 'cluster_name'
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = data.aws_eks_cluster.eks_cluster.name
}

# Provider Kubernetes pour interagir avec le cluster EKS
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_cluster.token
}

# Groupe de sécurité pour les nœuds EKS
resource "aws_security_group" "eks_nodes_sg" {
  vpc_id = var.vpc_id

  ingress {
    description = "Allow all traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Groupe de sécurité pour EC2 (bastion host)
resource "aws_security_group" "bastion_sg" {
  vpc_id = var.vpc_id

  ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Bastion Host pour se connecter aux nœuds EKS
resource "aws_instance" "bastion" {
  ami             = "ami-0ad5085afd25c69db"
  instance_type   = "t3.micro"
  key_name        = var.ssh_key_name
  subnet_id       = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]  # Remplacé ici 

  tags = {
    Name = "Bastion-Host"
  }
}


# Optionnel: Créer un Secret Kubernetes pour les identifiants de la base de données
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = "default"
  }

  data = {
    DB_HOST     = var.db_host
    DB_PORT     = var.db_port
    DB_USER     = var.db_user
    DB_PASSWORD = var.db_password
    DB_NAME     = var.db_name
  }
}

resource "kubernetes_secret" "docker_hub_secret" {
  metadata {
    name = "docker-hub-secret"
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "https://index.docker.io/v1/" = {
          username = var.docker_username
          password = var.docker_password
          email    = var.docker_email
          auth     = base64encode("${var.docker_username}:${var.docker_password}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_deployment" "app_with_db" {
  metadata {
    name = "my-app-deployment"
    labels = {
      app = "my-app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "my-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-app"
        }
      }

      spec {
        container {
         name  = "hello-node-v2"
        image = var.app_image  # Utilise la variable Terraform pour l'image Docker

        port {
        container_port = 3000  # Assurez-vous que l’application écoute sur ce port
        }
          
          # Variables d'environnement pour la connexion à la base de données
          env {
            name  = "DB_HOST"
            value = var.db_host
          }

          env {
            name  = "DB_PORT"
            value = var.db_port
          }

          env {
            name  = "DB_USER"
            value = var.db_user
          }

          env {
            name  = "DB_PASSWORD"
            value = var.db_password
          }

          env {
            name  = "DB_NAME"
            value = var.db_name
          }
        }

        image_pull_secrets {
          name = kubernetes_secret.docker_hub_secret.metadata[0].name
        }

        toleration {
          key      = "node.kubernetes.io/not-ready"
          operator = "Exists"
          effect   = "NoExecute"
          toleration_seconds = 300
        }

        toleration {
          key      = "node.kubernetes.io/unreachable"
          operator = "Exists"
          effect   = "NoExecute"
          toleration_seconds= 300
        }
      }
    }
  }
}

