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
