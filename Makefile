SHELL:=/bin/bash
PWD ?= $(PWD)

.DEFAULT_GOAL := all

all: apkbuild build

.PHONY: apkbuild
apkbuild:
	cd ${PWD}/apk-build ; \
	make build

.PHONY: build
build: build_latest build_full build_data build_data_full 

build_latest: 
	cd ${PWD} ; \
	docker build --no-cache -t securecompliance/gvm:no-data -t securecompliance/gvm:latest .
build_full: 
	cd ${PWD} ; \
	docker build --build-arg OPT_PDF=1  -t securecompliance/gvm:full .
build_data: 
	cd ${PWD} ; \
	docker build --build-arg SETUP=1 -t securecompliance/gvm:data .
build_data_full: 
	cd ${PWD} ; \
	docker build --build-arg SETUP=1 --build-arg OPT_PDF=1 -t securecompliance/gvm:data-full .
	
run_latest:
	mkdir -p ${PWD}/storage/postgres-db
	mkdir -p ${PWD}/storage/openvas-plugins
	mkdir -p ${PWD}/storage/gvm
	mkdir -p ${PWD}/storage/ssh
	docker run --rm --publish 8080:9392 --publish 5432:5432 --publish 2222:22 \
	--env DB_PASSWORD="postgres DB password" \
	--env PASSWORD="webUI password" \
	--env SSHD="true" \
	--cap-add=SYS_PTRACE \
	--privileged --ulimit core=-1 --security-opt seccomp=unconfined \
	--mount type=bind,source=/var/crash/,target=/var/crash/ \
	--volume "${PWD}/storage/postgres-db:/opt/database" \
	--volume "${PWD}/storage/openvas-plugins:/var/lib/openvas/plugins" \
	--volume "${PWD}/storage/gvm:/var/lib/gvm" \
	--volume "${PWD}/storage/ssh:/etc/ssh" \
	--name gvm securecompliance/gvm:latest

run_full:
	mkdir -p ${PWD}/storage/postgres-db
	mkdir -p ${PWD}/storage/openvas-plugins
	mkdir -p ${PWD}/storage/gvm
	mkdir -p ${PWD}/storage/ssh
	docker run --rm --publish 8080:9392 --publish 5432:5432 --publish 2222:22 \
	--env DB_PASSWORD="postgres DB password" \
	--env PASSWORD="webUI password" \
	--env SSHD="true" \
	--cap-add=SYS_PTRACE \
	--privileged --ulimit core=-1 --security-opt seccomp=unconfined \
	--mount type=bind,source=/var/crash/,target=/var/crash/ \
	--volume "${PWD}/storage/postgres-db:/opt/database" \
	--volume "${PWD}/storage/openvas-plugins:/var/lib/openvas/plugins" \
	--volume "${PWD}/storage/gvm:/var/lib/gvm" \
	--volume "${PWD}/storage/ssh:/etc/ssh" \
	--name gvm securecompliance/gvm:data-full