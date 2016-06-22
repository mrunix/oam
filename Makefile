### Makefile for oam

# Ensure GOARCH is set before running build process.
ifeq "$(GOARCH)" ""
  export GOARCH := amd64
endif

# Ensure GOPATH is set before running build process.
ifeq "$(GOPATH)" ""
  export GOPATH := $(CURDIR)/3rdparty
endif

path_to_add := $(addsuffix /bin,$(subst :,/bin:,$(GOPATH)))
export PATH := $(path_to_add):$(PATH)

# Check the version of make and set env varirables/commands accordingly.
version_list := $(subst ., ,$(MAKE_VERSION))
major_version := $(firstword $(version_list))
old_versions := 0 1 2 3
ifeq "$(major_version)" "$(filter $(major_version),$(old_versions))"
  # Old version of `make` installed. It fails to search golex/goyacc
  # by using the modified `PATH`, so we specify these commands with full path.
  GODEP   = $$(which godep)
  GOLEX   = $$(which golex)
  GOYACC  = $$(which goyacc)
  GOLINT  = $$(which golint)
else
  # After version 4, `make` could follow modified `PATH` to find
  # golex/goyacc correctly.
  GODEP   := godep
  GOLEX   := golex
  GOYACC  := goyacc
  GOLINT  := golint
endif

GO        := $(GODEP) go
ARCH      := "`uname -s`"
LINUX     := "Linux"
MAC       := "Darwin"

TARGET = ""
BUILD_FLAGS = -i

.PHONY: godep all build install clean cleanall todo test gotest webserver

all: godep build test check

godep:
	go get github.com/tools/godep
	go get github.com/gin-gonic/gin

build:
	$(GO) build

install:
	$(GO) install ./...

update:
	go get -u github.com/gin-gonic/gin

TEMP_FILE = temp_parser_file

check:
	go get github.com/golang/lint/golint

	@echo "vet"
	@ go tool vet . 2>&1 | grep -vE 'Godeps|3rdparty' | awk '{print} END{if(NR>0) {exit 1}}'
	@echo "vet --shadow"
	@ go tool vet --shadow . 2>&1 | grep -vE 'Godeps|3rdparty' | awk '{print} END{if(NR>0) {exit 1}}'
	@echo "golint"
	@ $(GOLINT) ./... 2>&1 | grep -vE 'LastInsertId|NewLexer|3rdparty' | awk '{print} END{if(NR>0) {exit 1}}'
	@echo "gofmt (simplify)"
	@ gofmt -s -l . 2>&1 | grep -vE 'Godeps|3rdparty' | awk '{print} END{if(NR>0) {exit 1}}'

clean:
	$(GO) clean -i ./...
	rm -rf *.out

cleanall: clean
	rm -rf $(GOPATH)/pkg

todo:
	@grep -n ^[[:space:]]*_[[:space:]]*=[[:space:]][[:alpha:]][[:alnum:]]* */*.go || true
	@grep -n TODO */*.go || true
	@grep -n BUG */*.go  || true
	@grep -n println */*.go || true

test: gotest

gotest:
	$(GO) test -cover ./...

race:
	$(GO) test --race -cover ./...

webserver:
	@cd webserver && $(GO) build $(BUILD_FLAGS)

