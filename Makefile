DO_INSTANCE_TAGNAME=celestia-testnet

terraform-apply:
	cd tf && terraform refresh -var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]'
	cd tf && terraform validate
	cd tf && terraform apply -var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]'

hosts:
	echo "[validators]" > ./ansible/hosts
	doctl compute droplet list --tag-name $(DO_INSTANCE_TAGNAME) --tag-name "celestia-node" | tail -n+2   |  tr -s ' ' | cut -d' ' -f2,3 | sort -k1 | sed 's/\(.*\) \(.*\)/\2 name=\1/g' >> ./ansible/hosts
	echo "[prometheus]" >> ./ansible/hosts
	doctl compute droplet list --tag-name $(DO_INSTANCE_TAGNAME) --tag-name "celestia-observability" | tail -n+2 |  tr -s ' ' | cut -d' ' -f3   >> ./ansible/hosts

terraform-destroy:
	cd tf && terraform destroy  -var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]'

ansible-install:
	cd ansible && ansible-playbook -i hosts -u root base.yaml
	cd ansible && ansible-playbook -i hosts -u root init-testapp.yaml
	cd ansible && ansible-playbook -i hosts -u root update-testapp.yaml

update:
	cd ansible && ansible-playbook -i hosts -u root update-testapp.yaml

start-network:
	cd ansible && ansible-playbook -i hosts -u root start-testapp.yaml

prometheus-init:
	cd ansible && ansible-playbook -i hosts  -u root prometheus.yaml

all: terraform-apply hosts ansible-install prometheus-init start-network
