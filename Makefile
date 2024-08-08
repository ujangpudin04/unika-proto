# GO_MODULE
GO_MODULE := github.com/ujangpudin04/unika-proto

# Detect the operating system
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')

.PHONY: clean
clean:
ifeq ($(OS), windows_nt)
	if exist "protogen" rd /s /q protogen
	mkdir protogen\go
else
	rm -rf ./protogen 
	mkdir -p ./protogen/go
endif


.PHONY: protoc-go
protoc-go:
	protoc -I . \
		-I ./proto \
		--go_opt=module=${GO_MODULE} --go_out=. \
		--go-grpc_opt=module=${GO_MODULE} --go-grpc_out=. \
		./proto/user/*.proto \
		./proto/hello/*.proto \
		./proto/google/type/*.proto # <-- Make sure this line is included to explicitly point to the directory

.PHONY: build
build: clean protoc-go

.PHONY: pipeline-init
pipeline-init:
	sudo apt-get install -y protobuf-compiler golang-goprotobuf-dev
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

.PHONY: pipeline-build
pipeline-build: pipeline-init build

# gRPC Gateway
.PHONY: clean-gateway
clean-gateway:
ifeq ($(OS), windows_nt)
	if exist "protogen\gateway" rd /s /q protogen\gateway
	mkdir protogen\gateway\go
	mkdir protogen\gateway\openapiv2
else
	rm -rf ./protogen/gateway
	mkdir -p ./protogen/gateway/go
	mkdir -p ./protogen/gateway/openapiv2
endif

.PHONY: protoc-go-gateway
protoc-go-gateway:
	protoc -I . \
		-I ./proto \
		--grpc-gateway_out ./protogen/gateway/go \
		--grpc-gateway_opt logtostderr=true \
		--grpc-gateway_opt paths=source_relative \
		--grpc-gateway_opt grpc_api_configuration=./grpc-gateway/config.yml \
		--grpc-gateway_opt standalone=true \
		--grpc-gateway_opt generate_unbound_methods=true \
		./proto/user/*.proto \
		./proto/hello/*.proto \
		./proto/google/type/*.proto # <-- Ensure this is included as well

.PHONY: protoc-openapiv2-gateway
protoc-openapiv2-gateway:
	protoc -I . \
		-I ./proto \
		--openapiv2_out ./protogen/gateway/openapiv2 \
		--openapiv2_opt logtostderr=true \
		--openapiv2_opt output_format=yaml \
		--openapiv2_opt grpc_api_configuration=./grpc-gateway/config.yml \
		--openapiv2_opt generate_unbound_methods=true \
		--openapiv2_opt allow_merge=true \
		--openapiv2_opt merge_file_name=merged \
		./proto/user/*.proto \
		./proto/hello/*.proto \
		./proto/google/type/*.proto # <-- Same here

.PHONY: build-gateway
build-gateway: clean-gateway protoc-go-gateway

.PHONY: pipeline-init-gateway
pipeline-init-gateway:
	go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest
	go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest

.PHONY: pipeline-build-gateway
pipeline-build-gateway: pipeline-init-gateway build-gateway protoc-openapiv2-gateway
