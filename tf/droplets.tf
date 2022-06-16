resource "digitalocean_droplet" "node" {
  count    = var.testnet_size
  name     = var.instance_names[count.index]
  image    = "debian-11-x64"
  region   = "fra1"
  tags     = concat(var.instance_tags, ["testnet-node"])
  size     = "s-4vcpu-8gb"
  ssh_keys = var.ssh_keys
}

resource "digitalocean_droplet" "monitor" {
  name     = "monitor"
  image    = "debian-11-x64"
  region   = "fra1"
  tags     = concat(var.instance_tags, ["testnet-observability"])
  size     = "s-4vcpu-8gb"
  ssh_keys = var.ssh_keys
}
