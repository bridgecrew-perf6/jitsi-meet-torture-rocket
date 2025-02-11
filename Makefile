ifneq (,$(wildcard ./env.d/terraform))
    include env.d/terraform
    export
endif

bootstrap: ## Bootstrap the Jitsi-Meet-torture project
	cp env.d/docker.dist env.d/docker
	cp env.d/terraform.dist env.d/terraform

build: ## Build the Jitsi-Meet-torture image with the specified configuration
ifneq (${shell ./bin/scaleway-cli instance image list | grep "${IMAGE_NAME} " | cut -d " " -f1},)
	make destroy-images
endif
ifneq ($(wildcard ./env.d/docker),)
	./bin/packer build -var SCALEWAY_INSTANCE_TYPE=${SCALEWAY_INSTANCE_TYPE} -var IMAGE_NAME=${IMAGE_NAME} packer.json
else 
	@echo "ERROR: The file env.d/docker doesn't exist."
endif

apply: ## Apply to terraform to deploy ressources and launch tests
	./bin/terraform apply -parallelism=${TF_OPERATIONS_PARALLELISM}
	
encrypt-key: ## Encrypt the secret key
	gpg --symmetric --armor --batch --passphrase="${SECRET_GPG_PASSPHRASE}" --output packer/.ssh/secrets.key.gpg packer/.ssh/id_ed25519

decrypt-key: ## Decrypt the secret key
	gpg --decrypt --batch --passphrase="${SECRET_GPG_PASSPHRASE}" packer/.ssh/secrets.key.gpg > packer/.ssh/id_ed25519

destroy-images: ## Delete the images created 
	./bin/scaleway-cli instance image delete ${shell ./bin/scaleway-cli instance image list | grep "${IMAGE_NAME} " | cut -d " " -f1} zone=fr-par-1
	./bin/scaleway-cli instance snapshot delete ${shell ./bin/scaleway-cli instance snapshot list | grep "${IMAGE_NAME}"-snapshot | cut -d " " -f1} zone=fr-par-1

destroy-terraform: ## Destroy terraform ressources that were created
	./bin/terraform destroy -parallelism=${TF_OPERATIONS_PARALLELISM}

destroy: \
	destroy-terraform \
	destroy-images
