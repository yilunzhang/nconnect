.DEFAULT_GOAL:=local_or_with_proxy

USE_PROXY=GOPROXY=https://goproxy.io
VERSION:=$(shell git describe --abbrev=7 --dirty --always --tags)
LDFLAGS="-s -w -X github.com/nknorg/nconnect/config.Version=$(VERSION)"
BUILD=go build -ldflags $(LDFLAGS)
XGO_MODULE=github.com/nknorg/nconnect
XGO_BUILD=xgo -ldflags $(LDFLAGS) --targets=$(XGO_TARGET) $(XGOFLAGS)
BUILD_DIR=build
BIN_NAME=nConnect
ifdef GOARM
BIN_DIR=$(GOOS)-$(GOARCH)v$(GOARM)
XGO_TARGET=$(GOOS)/$(GOARCH)-$(GOARM)
else
BIN_DIR=$(GOOS)-$(GOARCH)
XGO_TARGET=$(GOOS)/$(GOARCH)
endif

web/dist: $(shell find web/src -type f -not -path "web/src/node_modules/*" -not -path "web/src/build/*")
	-@cd web/src && yarn && yarn build && rm -rf ../dist && cp -a ./build ../dist

.PHONY: local
local: web/dist
	$(BUILD) -o $(BIN_NAME)$(EXT) .

.PHONY: local_with_proxy
local_with_proxy: web/dist
	$(USE_PROXY) $(BUILD) -o $(BIN_NAME)$(EXT) .

.PHONY: local_or_with_proxy
local_or_with_proxy:
	${MAKE} local || ${MAKE} local_with_proxy

.PHONY: build
build: web/dist
	rm -rf $(BUILD_DIR)/$(BIN_DIR)
	mkdir -p $(BUILD_DIR)/$(BIN_DIR)
	cd $(BUILD_DIR)/$(BIN_DIR) && $(XGO_BUILD) -out $(BIN_NAME) $(XGO_MODULE) && mv $(BIN_NAME)* $(BIN_NAME)$(EXT)
	mkdir -p $(BUILD_DIR)/$(BIN_DIR)/web/
	@cp -a web/dist $(BUILD_DIR)/$(BIN_DIR)/web/
	${MAKE} tar

.PHONY: tar
tar:
	cd $(BUILD_DIR) && rm -f $(BIN_DIR).tar.gz && tar --exclude ".DS_Store" --exclude "__MACOSX" -czvf $(BIN_DIR).tar.gz $(BIN_DIR)

.PHONY: zip
zip:
	cd $(BUILD_DIR) && rm -f $(BIN_DIR).zip && zip --exclude "*.DS_Store*" --exclude "*__MACOSX*" -r $(BIN_DIR).zip $(BIN_DIR)

.PHONY: all
all:
	${MAKE} build GOOS=darwin GOARCH=amd64
	${MAKE} build GOOS=linux GOARCH=amd64
	${MAKE} build GOOS=linux GOARCH=arm64
	${MAKE} build GOOS=linux GOARCH=arm GOARM=5
	${MAKE} build GOOS=linux GOARCH=arm GOARM=6
	${MAKE} build GOOS=linux GOARCH=arm GOARM=7
	${MAKE} build GOOS=windows GOARCH=amd64 EXT=.exe
	${MAKE} build GOOS=windows GOARCH=386 EXT=.exe
