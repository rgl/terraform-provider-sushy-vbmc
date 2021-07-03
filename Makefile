HOSTNAME=registry.terraform.io
NAMESPACE=rgl
NAME=sushy-vbmc
BINARY=terraform-provider-${NAME}
VERSION?=0.1.0
OS_ARCH=$(shell go env GOOS)_$(shell go env GOARCH)

default: install

build: sushy-vbmc-emulator
	go build -o ${BINARY}

sushy-vbmc-emulator:
	docker build -t ruilopes/sushy-vbmc-emulator sushy-vbmc-emulator

install: build
	mkdir -p ~/.terraform.d/plugins/${HOSTNAME}/${NAMESPACE}/${NAME}/${VERSION}/${OS_ARCH}
	mv ${BINARY} ~/.terraform.d/plugins/${HOSTNAME}/${NAMESPACE}/${NAME}/${VERSION}/${OS_ARCH}

uninstall:
	rm -f .terraform.lock.hcl
	rm -rf .terraform/providers/${HOSTNAME}/${NAMESPACE}/${NAME}
	rm -rf ~/.terraform.d/plugins/${HOSTNAME}/${NAMESPACE}/${NAME}

.PHONY: default build sushy-vbmc-emulator install uninstall
