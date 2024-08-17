PHONY: start reset update dependencies

start:
	./start.sh

reset:
	./scripts/reset-laminar.sh

update:
	./scripts/update-laminar.sh

dependencies:
	./scripts/install.sh