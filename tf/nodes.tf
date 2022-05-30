variable "testnet_size" {
  type = number
  default = 20
}

variable "ssh_keys" {
	type = list(string)
}

resource "digitalocean_droplet" "v036-testnet-node" {
  count        = var.testnet_size
  name         = "v036-testnet-node"
  image        = "debian-11-x64"
  region       = "fra1"
  tags = ["v036-testnet"]
  size = "s-4vcpu-8gb"
  ssh_keys = var.ssh_keys
}
