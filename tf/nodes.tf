variable "testnet_size" {
  type = number
  default = 20
}

variable "ssh_keys" {
	type = list(string)
}

variable "instance_tags" {
	type = list(string)
	default = ["v036-testnet"]
}

resource "digitalocean_droplet" "testnet-node" {
  count        = var.testnet_size
  name         = "validator${count.index}"
  image        = "debian-11-x64"
  region       = "fra1"
  tags = var.instance_tags
  size = "s-4vcpu-8gb"
  ssh_keys = var.ssh_keys
}

resource "digitalocean_droplet" "testnet-prometheus" {
  name         = "testnet-prometheus"
  image        = "debian-11-x64"
  region       = "fra1"
  tags = var.instance_tags
  size = "s-4vcpu-8gb"
  ssh_keys = var.ssh_keys
}
