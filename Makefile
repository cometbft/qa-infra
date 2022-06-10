DO_INSTANCE_TAGNAME=v035-testnet
export DO_INSTANCE_TAGNAME

.PHONY: terraform-init
terraform-init:
	$(MAKE) -C ./tf/ init

.PHONY: terraform-apply
terraform-apply:
	$(MAKE) -C ./tf/ apply

.PHONY: hosts
hosts:
	echo "[validators]" > ./ansible/hosts
	doctl compute droplet list --tag-name $(DO_INSTANCE_TAGNAME) --tag-name "testnet-node" | tail -n+2   |  tr -s ' ' | cut -d' ' -f2,3 | sort -k1 | sed 's/\(.*\) \(.*\)/\2 name=\1/g' >> ./ansible/hosts
	echo "[prometheus]" >> ./ansible/hosts
	doctl compute droplet list --tag-name $(DO_INSTANCE_TAGNAME) --tag-name "testnet-observability" | tail -n+2 |  tr -s ' ' | cut -d' ' -f3   >> ./ansible/hosts

.PHONY: configgen
configgen:
	./script/configgen.sh `tail -n+2 ./ansible/hosts | head -n -2 |cut -d' ' -f1| paste -s -d, -`

.PHONY: ansible-install
ansible-install:
	cd ansible && \
		ansible-playbook -i hosts -u root base.yaml -f 10 && \
		ansible-playbook -i hosts -u root prometheus-node-exporter.yaml -f 10 \
		ansible-playbook -i hosts -u root init-testapp.yaml -f 10 && \
		ansible-playbook -i hosts -u root update-testapp.yaml -f 10

.PHONY: prometheus-init
prometheus-init:
	cd ansible && ansible-playbook -i hosts  -u root prometheus.yaml -f 10

.PHONY: start-network
start-network:
	cd ansible && ansible-playbook -i hosts -u root start-testapp.yaml -f 10

.PHONY: runload
runload:
	# TODO(thane): What is this "runner"?
	runner load --ip-list `tail -n+2 ./ansible/hosts | head -n -2 |cut -d' ' -f1| paste -s -d, -` --seed-delta $(shell echo $$RANDOM)

.PHONY: terraform-destroy
terraform-destroy:
	$(MAKE) -C ./tf/ destroy

