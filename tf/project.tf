resource "digitalocean_project" "v036-tm-testnet" {
  name        = "v036-tm-testnet"
  description = "A project to test version v0.36 of the Tendermint project."
  resources = [for node in digitalocean_droplet.v036-testnet-node: node.urn]
}
