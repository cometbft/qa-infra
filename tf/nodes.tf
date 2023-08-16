variable "testnet_size" {
  type = number
  default = 20
}

variable "ssh_keys" {
	type = list(string)
}

variable "instance_tags" {
	type = list(string)
	default = ["cometbft-testnet-default"]
}

variable "instance_names" {
	type = list(string)
}

variable "ephemeral_size" {
  type = number
  default = 0
}

variable "ephemeral_names" {
  type = list(string)
}

variable "vpc_subnet" {
  type = string
}

resource "digitalocean_vpc" "testnet-vpc" {
  name     = replace("vpc-cometbft-${var.vpc_subnet}", "/[/.]/", "-")
  region   = "fra1"
  ip_range = var.vpc_subnet
}

resource "digitalocean_droplet" "testnet-node" {
  count    = var.testnet_size
  name     = var.instance_names[count.index]
  image    = "debian-11-x64"
  region   = "fra1"
  tags     = concat(var.instance_tags, ["testnet-node"])
  size     = "s-4vcpu-8gb"
  vpc_uuid = digitalocean_vpc.testnet-vpc.id
  ssh_keys = var.ssh_keys
}

resource "digitalocean_droplet" "testnet-prometheus" {
  name     = "testnet-prometheus"
  image    = "debian-11-x64"
  region   = "fra1"
  tags     = concat(var.instance_tags, ["testnet-observability"])
  size     = "s-4vcpu-8gb"
  vpc_uuid = digitalocean_vpc.testnet-vpc.id
  ssh_keys = var.ssh_keys
}

resource "digitalocean_droplet" "testnet-load-runner" {
  name     = "testnet-load-runner"
  image    = "debian-11-x64"
  region   = "fra1"
  tags     = concat(var.instance_tags, ["testnet-load"])
  size     = "s-8vcpu-16gb"
  vpc_uuid = digitalocean_vpc.testnet-vpc.id
  ssh_keys = var.ssh_keys
}

resource "digitalocean_droplet" "ephemeral-node" {
  count        = var.ephemeral_size
  name         = var.ephemeral_names[count.index]
  image        = "debian-11-x64"
  region       = "fra1"
  tags         = concat(var.instance_tags, ["ephemeral-node"])
  size         = "s-4vcpu-8gb"
  vpc_uuid     = digitalocean_vpc.testnet-vpc.id
  ssh_keys     = var.ssh_keys
}
