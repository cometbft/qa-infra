DO_INSTANCE_TAGNAME=v035-testnet

configgen:
	./script/configgen.sh `tail -n+2 ./ansible/hosts | head -n -2 |cut -d' ' -f1| paste -s -d, -`

terraform-apply:
	cd tf && terraform refresh -var='testnet_size=$(shell grep "\[node..*\]" ./testnet.toml -c)' -var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' -var='instance_names=[$(shell grep '\[node..*\]' ./testnet.toml | sed -e 's/\[node\.\(.*\)]/"\1"/' | sort | paste -s -d, -)]'
	cd tf && terraform validate
	cd tf && terraform apply -var='testnet_size=$(shell grep "\[node..*\]" ./testnet.toml -c)' -var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' -var='instance_names=[$(shell grep '\[node..*\]' ./testnet.toml | sed -e 's/\[node\.\(.*\)]/"\1"/' | sort | paste -s -d, -)]'

hosts:
	echo "[validators]" > ./ansible/hosts
	doctl compute droplet list --tag-name $(DO_INSTANCE_TAGNAME) --tag-name "testnet-node" | tail -n+2   |  tr -s ' ' | cut -d' ' -f2,3 | sort -k1 | sed 's/\(.*\) \(.*\)/\2 name=\1/g' >> ./ansible/hosts
	echo "[prometheus]" >> ./ansible/hosts
	doctl compute droplet list --tag-name $(DO_INSTANCE_TAGNAME) --tag-name "testnet-observability" | tail -n+2 |  tr -s ' ' | cut -d' ' -f3   >> ./ansible/hosts

terraform-destroy:
	cd tf && terraform destroy -var='testnet_size=$(shell grep "\[node..*\]" ./testnet.toml -c)' -var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' -var='instance_names=[$(shell grep '\[node..*\]' ./testnet.toml | sed -e 's/\[node\.\(.*\)]/"\1"/' | sort | paste -s -d, -)]'

ansible-install:
	cd ansible && ansible-playbook -i hosts -u root base.yaml -f 10
	cd ansible && ansible-playbook -i hosts -u root prometheus-node-exporter.yaml -f 10
	cd ansible && ansible-playbook -i hosts -u root init-testapp.yaml -f 10
	cd ansible && ansible-playbook -i hosts -u root update-testapp.yaml -f 10

start-network:
	cd ansible && ansible-playbook -i hosts -u root start-testapp.yaml -f 10

prometheus-init:
	cd ansible && ansible-playbook -i hosts  -u root prometheus.yaml -f 10

runload:
	runner load --ip-list `tail -n+2 ./ansible/hosts | head -n -2 |cut -d' ' -f1| paste -s -d, -` --seed-delta $(shell echo $$RANDOM)

all: configgen terraform-apply hosts ansible-install prometheus-init start-network
