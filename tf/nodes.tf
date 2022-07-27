variable "testnet_size" {
  type = number
  default = 20
}

variable "ssh_keys" {
	type = list(string)
}

variable "instance_tags" {
	type = list(string)
	default = ["v035-testnet"]
}

variable "instance_names" {
	type = list(string)
}

resource "digitalocean_droplet" "testnet-node" {
  count    = var.testnet_size
  name     = var.instance_names[count.index]
  image    = "debian-11-x64"
  region   = "fra1"
  tags     = concat(var.instance_tags, ["testnet-node"])
  size     = "s-2vcpu-4gb"
  ssh_keys = var.ssh_keys
}

resource "digitalocean_droplet" "testnet-prometheus" {
  name     = "testnet-prometheus"
  image    = "debian-11-x64"
  region   = "fra1"
  tags     = concat(var.instance_tags, ["testnet-observability"])
  size     = "s-2vcpu-4gb"
  ssh_keys = var.ssh_keys
}
