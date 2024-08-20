PHONY: laminar reset update dependencies

laminar:
	./start.sh

reset:
	./scripts/reset-laminar.sh

update:
	./scripts/update-laminar.sh

dependencies:
	./scripts/install.sh