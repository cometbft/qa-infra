resource "digitalocean_project" "cmt-testnet" {
  name        = "cmt-testnet"
  description = "A project to test the CometBFT codebase."
  resources   = concat([for node in digitalocean_droplet.testnet-node: node.urn], [digitalocean_droplet.testnet-prometheus.urn], [digitalocean_droplet.testnet-load-runner.urn], [for node in digitalocean_droplet.ephemeral-node: node.urn])
}
