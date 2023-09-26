all: setup

setup:
	ansible-playbook -i ansible/inventory ansible/grafana-setup.yml

# Mainly for debugging ansible playbooks and tasks.
clean:
	ansible-playbook -i ansible/inventory ansible/grafana-clean.yml

.PHONY: all setup clean
