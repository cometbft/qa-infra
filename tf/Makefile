
# apply the terraform plan to 
.PHONY: terraform-apply
terraform-apply:
	terraform refresh
	terraform validate
	terraform apply

.PHONY: terraform-destroy
terraform-destroy:
	terraform refresh
	terraform validate
	terraform destroy
