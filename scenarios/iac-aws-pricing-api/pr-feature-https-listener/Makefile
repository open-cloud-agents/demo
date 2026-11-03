.PHONY: init init-offline validate plan fmt clean

# Dummy credentials so validate and plan never reach into the client account.
OFFLINE_ENV = AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=eu-west-1

init: clean
	terraform init

# Providers only, no state bucket access needed.
init-offline:
	terraform init -backend=false

validate:
	terraform validate

plan: local_override.tf
	$(OFFLINE_ENV) terraform init -reconfigure -input=false
	$(OFFLINE_ENV) terraform plan -refresh=false -var name_suffix=local

fmt:
	terraform fmt -recursive

# Points state at a local file so plan works with no credentials. Gitignored, and
# removed by "make init" so it cannot leak into a run against the real backend.
local_override.tf:
	printf 'terraform {\n  backend "local" {}\n}\n' > $@

clean:
	rm -f local_override.tf
