variable "ssh_keys" {
	type = list(string)
}

variable "instance_tags" {
	type = list(string)
}

resource "digitalocean_droplet" "celestia-node" {
  name         = var.instance_names[count.index]
  image        = "debian-11-x64"
  region       = "fra1"
  tags = concat(var.instance_tags, ["celestia-node"])
  size = "s-4vcpu-8gb"
  ssh_keys = var.ssh_keys
}

resource "digitalocean_droplet" "testnet-prometheus" {
  name         = "celestia-prometheus"
  image        = "debian-11-x64"
  region       = "fra1"
  tags = concat(var.instance_tags, ["celestia-observability"])
  size = "s-4vcpu-8gb"
  ssh_keys = var.ssh_keys
}
