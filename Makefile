SHELL=/bin/bash
GOPATH:=$(shell go env GOPATH | tr '\\' '/')
GOEXE:=$(shell go env GOEXE)
GORELEASER:=$(GOPATH)/bin/goreleaser$(GOEXE)
HOSTNAME=registry.terraform.io
NAMESPACE=rgl
NAME=sushy-vbmc
BINARY=terraform-provider-${NAME}
VERSION?=0.3.0
OS_ARCH=$(shell go env GOOS)_$(shell go env GOARCH)

# see https://github.com/goreleaser/goreleaser
# renovate: datasource=github-releases depName=goreleaser/goreleaser extractVersion=^v?(?<version>2\..+)
GORELEASER_VERSION := 2.2.0

default: install

$(GORELEASER):
	go install github.com/goreleaser/goreleaser/v2@v$(GORELEASER_VERSION)

release-snapshot: $(GORELEASER)
	$(GORELEASER) release --snapshot --skip=publish --skip=sign --clean

build: sushy-vbmc-emulator
	go build -o ${BINARY}

sushy-vbmc-emulator:
	DOCKER_BUILDKIT=1 docker build -t ruilopes/sushy-vbmc-emulator sushy-vbmc-emulator

install: build
	mkdir -p ~/.terraform.d/plugins/${HOSTNAME}/${NAMESPACE}/${NAME}/${VERSION}/${OS_ARCH}
	mv ${BINARY} ~/.terraform.d/plugins/${HOSTNAME}/${NAMESPACE}/${NAME}/${VERSION}/${OS_ARCH}

uninstall:
	rm -f .terraform.lock.hcl
	rm -rf .terraform/providers/${HOSTNAME}/${NAMESPACE}/${NAME}
	rm -rf ~/.terraform.d/plugins/${HOSTNAME}/${NAMESPACE}/${NAME}

.PHONY: default build release-snapshot sushy-vbmc-emulator install uninstall
