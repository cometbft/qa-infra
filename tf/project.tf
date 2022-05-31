resource "digitalocean_project" "tm-testnet" {
  name        = "tm-testnet"
  description = "A project to test the Tendermint codebase."
  resources = [for node in digitalocean_droplet.testnet-node: node.urn]
}
