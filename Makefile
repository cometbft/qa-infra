DO_INSTANCE_TAGNAME=v036-testnet
TESTNET_SIZE=2

terraform-apply:
	cd tf && terraform refresh
	cd tf && terraform validate
	cd tf && terraform apply -var='testnet_size=$(TESTNET_SIZE)' -var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]'

terraform-destroy:
	cd tf && terraform destroy

hosts:
	echo "[validators]" > ./ansible/hosts
	doctl compute droplet list --tag-name $(DO_INSTANCE_TAGNAME) | head | tr -s ' ' | cut -d' ' -f3 | tail -n+2 >> ./ansible/hosts

configgen:
	./script/configgen.sh `tail -n+2 ./ansible/hosts | paste -s -d, -`
