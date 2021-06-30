PWD ?= $(PWD)
.DEFAULT_GOAL := all

all: apkbuild build

.PHONY: apkbuild
apkbuild:
	cd ${PWD}/apk-build ; \
	make build


.PHONY: build
build: 
	cd ${PWD} ; \
	docker build --no-cache  \
		-t securecompliance/gvm:nodata \
		-t securecompliance/gvm:latest \
		. ; \
	docker build --no-cache --build-arg SETUP=1 \ 
		-t securecompliance/gvm:data \
		.