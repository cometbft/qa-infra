resource "digitalocean_project" "tm-testnet" {
  name        = "tm-testnet"
  description = "A project to test the Tendermint codebase."
  resources   = concat([for node in digitalocean_droplet.node: node.urn], [digitalocean_droplet.monitor.urn])
}
