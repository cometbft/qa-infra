DO_INSTANCE_TAGNAME=v036-testnet
TESTNET_SIZE=20

terraform-apply:
	cd tf && terraform refresh
	cd tf && terraform validate
	cd tf && terraform apply -var='testnet_size=$(TESTNET_SIZE)' -var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]'

terraform-destroy:
	cd tf && terraform destroy

hosts:
	echo "[validators]" > ./ansible/hosts
	doctl compute droplet list --tag-name $(DO_INSTANCE_TAGNAME) | tr -s ' ' | cut -d' ' -f2,3 | sort -k1 | tail -n+2 | sed 's/\(.*\) \(.*\)/\2 name=\1/g' >> ./ansible/hosts

configgen:
	./script/configgen.sh `tail -n+2 ./ansible/hosts | cut -d' ' -f1| paste -s -d, -`

ansible-install:
	cd ansible && ansible-playbook -i hosts -u root base.yaml -f 10
	cd ansible && ansible-playbook -i hosts -u root init-testapp.yaml -f 10
	cd ansible && ansible-playbook -i hosts -u root update-testapp.yaml -f 10

start:
	cd ansible && ansible-playbook -i hosts -u root start-testapp.yaml -f 10

temp: hosts configgen ansible-install start