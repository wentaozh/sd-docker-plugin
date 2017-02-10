# building the sheepdog docker plugin golang binary with version
# makefile mostly used for packing a tpkg

.PHONY: all build install clean setup 

IMAGE_PATH=wentaozh/sd-docker-plugin
TAG?=latest
IMAGE=$(IMAGE_PATH):$(TAG)
SUDO?=


TMPDIR?=/tmp
INSTALL?=install


BINARY=sd-docker-plugin
PKG_SRC=main.go driver.go 

PACKAGE_BUILD=$(TMPDIR)/$(BINARY).tpkg.buildtmp

PACKAGE_BIN_DIR=$(PACKAGE_BUILD)/reloc/bin
PACKAGE_ETC_DIR=$(PACKAGE_BUILD)/reloc/etc


# Run these if you have a local dev env setup, otherwise they will / can be run
# in the container.
all: build

# set VERSION from version.go, eval into Makefile for inclusion into tpkg.yml
build: dist/$(BINARY)

dist/$(BINARY): $(PKG_SRC)
	go build -v -x -o dist/$(BINARY) .

install: build 
	go install .

clean:
	go clean

uninstall:
	@$(RM) -iv `which $(BINARY)`

dist:
	mkdir dist

# Used to have build env be inside container and to pull out the binary.
make/%: build_docker
	$(SUDO) docker run ${DOCKER_ARGS} --rm -i $(IMAGE) make $*

run:
	$(SUDO) docker run ${DOCKER_ARGS} --rm -it $(IMAGE)

build_docker:
	$(SUDO) docker build -t $(IMAGE) .

binary_from_container:
	$(SUDO) docker run ${DOCKER_ARGS} --rm -it \
		-v $${PWD}:/sd-docker-plugin/dist \
		-w /sd-docker-plugin \
		$(IMAGE) make build

local:
	$(SUDO) docker run ${DOCKER_ARGS} --rm -it \
		-v $${PWD}:/sd-docker-plugin \
		-w /sd-docker-plugin \
		$(IMAGE)


# build relocatable tpkg
# TODO: repair PATHS at install to set TPKG_HOME (assumed /home/ops)
package: build 
	$(RM) -fr $(PACKAGE_BUILD)
	mkdir -p $(PACKAGE_BIN_DIR) 
	$(INSTALL) $(PACKAGE_BUILD)/.
	$(INSTALL) dist/$(BINARY) $(PACKAGE_BIN_DIR)/.
	tpkg --make $(PACKAGE_BUILD) --out $(CURDIR)

