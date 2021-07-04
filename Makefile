SHELL:=/bin/bash
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
	docker build -t securecompliance/gvm:no-data -t securecompliance/gvm:latest . ; \
	docker build --build-arg OPT_PDF=1 -t securecompliance/gvm:no-data-full . ; \
	docker build --build-arg SETUP=1 -t securecompliance/gvm:data . ; 
	docker build --build-arg SETUP=1 --build-arg OPT_PDF=1 -t securecompliance/gvm:data-full . ; 
