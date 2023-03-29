# Play with Terraform

## Introduction 

Ce repository a pour but d'expliquer point par point comment déployer des objets sur **AWS** grâce à Terraform par le biais d'un module, ce module pourra ainsi par la suite être réuitilisés pour déployer d'autre infrastructure type et donc gagner du temps sur le déploiement et la conception de l'infrastructure.

Ce projet a été réalisé par :
- ROQUES Baptiste 5SRC4
- MOUROT Damien 5SRC4

## Prérequis 

- Posséder un compte AWS et/ou AWS Academy
- Avoir un environnement de travail Windows ou Linux

## Préparation de l'environnement

Dans notre projet nous avons fait le choix de manipuler **Terraform** depuis un serveur Linux, après avoir testé divers environnements de travail. Effectivement nous avons jugé plus judicieux d'installer **Terraform** sur un environnement Linux pour sa facilité d'installation et sa gestion des versions.

Voici les commandes à effectué pour installer **Terraform** sur un serveur **CentOS 7.9** 



### Téléchargment du binaire
```
wget https://releases.hashicorp.com/terraform/0.15.4/terraform_0.15.4_linux_amd64.zip
```
### Décompression de l'archive téléchargé
```
unzip terraform_0.15.4_linux_amd64.zip
```
### Nous déplaçons le dossier terraform dans le dossier contenant nos binaires
```
sudo mv terraform /usr/local/bin/
```
### Verifier que **Terraform** est bien installé 
```
terraform --version
```
Une fois que **Terraform** est correctement installé, vous pouvez passer à la prochaine étape.

## Providers

Dans Terraform nous faisons appel à des providers qui vont nous permettre de se connecter à diverses plateformes tel que **AWS, Azure, VMWare**...

Etant donné que nous souhaitons déployer des objets sur AWS, nous allons choisir AWS comme notre prodivers.

Pour commencer veuillez créer un nouveau dossier portant le nom de votre choix et dans ce dossier créez ces trois fichiers : 
- main.tf
- variables.tf
- terraform.tfvars

*Pour rappel:* 

- *main.tf : Ce fichier contient la liste des ressources que Terraform doit créer, modifier ou détruire*

- *variables.tf : Fichier contenant les déclarations de nos variables*

- *terraform.tfvars : C'est dans ce fichier qu'on attribue des valeurs à nos variables*

Pour continuer nous allons remplir le fichier **main.tf** pour déclarer notre prodivers.

```
# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
  token      = var.aws_token
}
```

Vous pouvez constaster ci-dessus que nous avons fait appel à 4 variables, nous devons donc les déclarer dans le fichier **variables.tf**

```
# variables.tf

# Credentials
variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "aws_token" {
  type      = string
  sensitive = true
}
```
N'oubliez pas de remplir avec vos informations les varialbes dans le fichier **terraform.tfvars**.

``` 
# terraform.tfvars

# Credentials
aws_access_key = ""
aws_secret_key = ""
aws_token      = ""
```

Il faut désormais initaliser votre dossier courant contenant les fichiers terraform avec la commande : ```terraform init```


## Création du module

Comme vu au début de la documentation, nous allons manipuler un module pour déployer aisément nos objets sur **AWS**.

Pour cela vous devez créer un dossier **modules** et dans celui-ci créer un autre dossier nommée **infra**.

Dans ce dossier **infra** vous devrez créer les trois fichiers suivants :
- main.tf
- var.tf
- outputs.tf

### S3 Bucket
Les premiers objets que nous allons créer seront le **S3 Bucket** ainsi que ses propriétés.

```
# ./modules/infra/main.tf

# Create a S3 bucket
resource "aws_s3_bucket" "s3_Bucket" {
  bucket = var.bucket_name

}

# Add policy on our S3 Bucket
resource "aws_s3_bucket_policy" "s3_policy_only_ec2" {
  bucket = var.bucket_name

  policy = <<EOF
  {
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "AllowAccessToEC2Instance",
          "Effect": "Deny",
          "Principal": "*",
          "Action": "s3:*",
          "Resource": "arn:aws:s3:::${var.bucket_name}/*",
          "Condition": {
              "NotIpAddress": {
                  "aws:SourceIp": "${aws_instance.ec2-5src4.private_ip}"
              }
          }
      }
  ]
}
EOF
}
```

> La propriété créée stipule que sur la ressource S3 Bucket nous refusons tout accès à toute adresse IP n'étant pas celle de notre futur instance EC2.

### Instance EC2

Nous allons entâmer la création de l'instance EC2 grâce au code suivant : 

```
# ./modules/infra/main.tf

# Create an EC2 instance
resource "aws_instance" "ec2-5src4" {
  ami                         = var.ec2_ami
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.subnet_5src.id
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  tags = {
    Name = var.ec2_name
  }
}
```
> Cette instance sera relié à notre subnet et aura notre clé publique rattaché.

### Partie réseaux

- Création du réseau global et de son sous-réseau grâce aux objets **VPC** et **subnet**

```
# ./modules/infra/main.tf

# Create a VPC
resource "aws_vpc" "vpc_5src" {
  cidr_block = var.vpc_IP

  tags = {
    Name = var.vpc_tags_name
  }
}

# Create a subnet
resource "aws_subnet" "subnet_5src" {
  vpc_id     = aws_vpc.vpc_5src.id
  cidr_block = var.subnet_IP

  tags = {
    Name = var.subnet_tags_name
  }
}

```

- Création de la règle de pare-feu permettant l'accès au port 22 (SSH) et le rattachement de celle-ci à l'instance EC2.

```
# ./modules/infra/main.tf

# Create Security group
resource "aws_security_group" "aws_sg_ingress_only" {
  name        = var.sg_name
  description = "Allow ssh"
  vpc_id      = aws_vpc.vpc_5src.id


  ingress {
    description      = "Allow ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

# Attach the security group to the EC2 instance
resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = aws_security_group.aws_sg_ingress_only.id
  network_interface_id = aws_instance.ec2-5src4.primary_network_interface_id
}
```

- Création de la gateway et de sa route par défaut

```
# ./modules/infra/main.tf

# Connect the internet gateway to the VPC
resource "aws_internet_gateway" "ig_5src4" {
  vpc_id = aws_vpc.vpc_5src.id
}

# Create route to the internet gateway
resource "aws_route_table" "rt_5src4" {
  vpc_id = aws_vpc.vpc_5src.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig_5src4.id
  }
}

# Associate the route table to the subnetwork
resource "aws_route_table_association" "rt_association" {
  subnet_id      = aws_subnet.subnet_5src.id
  route_table_id = aws_route_table.rt_5src4.id
}

```

## Misc 

- Création du topic SNS pour l'envoi de mail

```
# ./modules/infra/main.tf

# Create SNS for sending mail when EC2 instance is created
resource "aws_sns_topic" "topic_5src4" {
  name = var.topic_name
}

resource "aws_sns_topic_subscription" "topic_sub_5src4" {
  topic_arn = aws_sns_topic.topic_5src4.arn
  protocol  = "email"
  endpoint  = var.topic_sub_dest
}
```

- Importation de notre clé publique SSH 

```
# ./modules/infra/main.tf

# Create key pair to ssh the EC2 instance
resource "aws_key_pair" "deploy_ssh_key" {
  key_name   = var.ssh_key_name
  public_key = var.public_key
}
```

- Nous souhaitons avoir en sortie du `terraform apply` l'ip publique de notre instance EC2

```
# ./modules/infra/outputs.tf 

output "myip" {
  value       = aws_instance.ec2-5src4.public_ip
  description = "Adress IP publique de l'instance"
}
```


<br>

> ⚠️ N'oubliez pas de déclarer les variables dans le fichier **./modules/infra/variables.tf** 

<br>

## Utilisation du module

Maintenant que notre module est prêt, nous sommes en mesure de l'appeler dans notre code.

```
# ./main.tf

module "tp_grp28" {
  source = "./modules/infra"

  # VPC
  vpc_IP        = var.vpc_IP
  vpc_tags_name = var.vpc_tags_name

  # Subnet
  subnet_tags_name = var.subnet_tags_name
  subnet_IP        = var.subnet_IP

  # Security Group
  sg_name = var.sg_name

  # Bucket
  bucket_name = var.bucket_name

  # EC2
  ec2_ami           = var.ec2_ami
  ec2_instance_type = var.ec2_instance_type
  ec2_name          = var.ec2_name

  # SSH Key pair
  ssh_key_name = var.ssh_key_name
  public_key   = var.public_key

  # SNS
  topic_name     = var.topic_name
  topic_sub_dest = var.topic_sub_dest

}

output "myip" {
  value       = module.tp_grp28.myip
  description = "Output the public ip of the instance"
}

```

<br>

> ⚠️ N'oubliez pas de déclarer les variables dans le fichier **./variables.tf** et de les remplir dans le fichier **./terraform.tfvars** 

<br>

Exemple du fichier **terraform.tfvars** : 

```
# ./terraform.tfvars

# Credentials
aws_access_key = ""
aws_secret_key = ""
aws_token      = ""

# VPC
vpc_IP        = "10.0.0.0/16"
vpc_tags_name = "vpc_infra"

#Security Group
sg_name = "sg_infra"

# Bucket
bucket_name = "bucket-5src4-g28"

# EC2 Instance
ec2_ami           = "ami-0b0dcb5067f052a63"
ec2_instance_type = "t2.micro"
ec2_name          = "DamBebou"

# Subnet
subnet_tags_name = "subnet-5src4-g28"
subnet_IP        = "10.0.1.0/24"

# SSH Key pair
ssh_key_name = "test_key"
public_key   = ""

# SNS
topic_name     = "topic_grp28"
topic_sub_dest = ""
```

## Déploiement de l'infrastucture

Notre infrastructure est fin prête à être déployée, pour visualiser les actions qui vont être faites : `terraform plan`

Dès lors que vous êtes prêt, lancez la commande : `terraform apply`

Celle-ci à la fin du déploiement devrais vous retourner l'ip publique de votre instance et donc vous pourrez vous y connecter en SSH.

## Conclusion

A la fin de cette documentation, vous avez acquis les compétences nécessaires pour créer des objets sur AWS grâce à **Terraform** et la création de module.

<br>

Baptiste & Damien.