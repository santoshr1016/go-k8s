export PATH := $(abspath ./vendor/bin):$(PATH)
export CGO_ENABLED=0
export GO111MODULE=on

GIT_VERSION=$(shell git describe --tags --always --dirty 2> /dev/null || echo 0.0.0)
LDFLAGS=-ldflags "-X main.Version=$(GIT_VERSION)"
BUFFER := $(shell mktemp)
REPORT_DIR=bin

GO_APP_BINARY := go-k8s
GOLANGCI=$(shell go env GOPATH)/bin/golangci-lint
GOFUMPT=$(shell go env GOPATH)/bin/gofumpt
REGISTRY := santoshr1016
REPO := santoshr1016/go-k8s
TAG := $(GIT_VERSION)

all: lint test go-k8s

.PHONY: go-k8s
go-k8s:
	mkdir -p $(REPORT_DIR)
	go build $(LDFLAGS) -a -installsuffix cgo -o $(REPORT_DIR)/$(GO_APP_BINARY) main.go

.PHONY: fmt
fmt:
	@echo "Fmt run"
	go fmt ./...

.PHONY: vet
vet:
	@echo "vet run"
	go vet ./...

.PHONY: lint
lint: ${GOLANGCI} yaml-lint
	@echo "Checking code style"
	@! test -s $(BUFFER)
	golangci-lint run --fix -vc ./.golangci.yaml ./...

${GOLANGCI}:
	go get github.com/golangci/golangci-lint/cmd/golangci-lint@v1.29.0

${GOFUMPT}:
	GO111MODULE=on go get mvdan.cc/gofumpt

.PHONY: lint-fix
lint-fix: fmt vet ${GOFUMPT}
	gofumpt -e -w .

.PHONY: yaml-lint
yaml-lint:
	yamllint -c .yamllint.conf ./

.PHONY: test
test:
	@echo "Running unit tests, TBD"
	go test -v ./...

run: go-k8s
	./$(REPORT_DIR)/$(GO_APP_BINARY)

.PHONY: ci
ci: lint test go-k8s

.PHONY: docker-login
docker-login:
	docker login --username santoshr1016 --password-stdin $(REGISTRY)

.PHONY: build-image
build-image: docker-login
	docker build -t $(REGISTRY)/$(REPO):$(TAG) .

.PHONY: push-image
push-image:
	docker push $(REGISTRY)/$(REPO):$(TAG)

.PHONY: release
release: build-image push-image

.PHONY: clean
clean:
	go clean
	rm -rf $(REPORT_DIR)
	docker rmi santoshr1016:latest $(REGISTRY)/$(REPO):$(TAG)
#
#.PHONY: pre-commit
#pre-commit:
#	make lint-fix lint
