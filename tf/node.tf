resource "digitalocean_droplet" "v036-testnet-node" {
  count        = 3
  name         = "v036-testnet-node"
  image        = "debian-11-x64"
  region       = "fra1"
  tags = ["v036-testnet"]
  size = "s-4vcpu-8gb"
}
