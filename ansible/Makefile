.PHONY: deploy
deploy:
	ansible-playbook -i hosts -u root base.yaml -f 10 && \
	ansible-playbook -i hosts -u root init-testapp.yaml -f 10 && \
	ansible-playbook -i hosts -u root update-testapp.yaml -f 10
