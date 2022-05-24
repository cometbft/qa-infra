resource "digitalocean_droplet" "v0.36-testnet-node" {
  name         = "v0.36-testnet-node"
  image        = "debian-11-x64"
  region       = "fra1"
  tags = ["v0.36-testnet"]
  size = "s-4vcpu-8gb"
}

