SHELL:=/bin/bash
PWD ?= $(PWD)
DOCKER_ORG:=securecompliance
PLATFORM:=linux/amd64,linux/arm64
ADD_OPTIONS:=--load
OPTIONS:=


.DEFAULT_GOAL := all

all: apkbuild build

.PHONY: apkbuild
apkbuild:
	cd ${PWD}/apk-build ; \
	make build

.PHONY: build_debian
build: build_debian_latest build_debian_full build_debian_data build_debian_data_full 

build_debian_squash:
	cd ${PWD} ; \
	docker build -f Dockerfile.debian --squash ${ADD_OPTIONS}  -t ${DOCKER_ORG}/gvm:debian . ; \
	docker push ${DOCKER_ORG}/gvm:debian
build_debian_latest: 
	cd ${PWD} ; \
	docker build --platform ${PLATFORM} ${ADD_OPTIONS} -f Dockerfile.debian -t ${DOCKER_ORG}/gvm:debian -t ${DOCKER_ORG}/gvm:debian-latest .
build_debian_full: 
	cd ${PWD} ; \
	docker build --platform ${PLATFORM} ${ADD_OPTIONS} -f Dockerfile.debian --build-arg OPT_PDF=1  -t ${DOCKER_ORG}/gvm:debian-full .
build_debian_data: 
	cd ${PWD} ; \
	docker build --platform ${PLATFORM} ${ADD_OPTIONS} -f Dockerfile.debian --build-arg SETUP=1 -t ${DOCKER_ORG}/gvm:debian-data .
build_debian_data_full: 
	cd ${PWD} ; \
	docker build --platform ${PLATFORM} ${ADD_OPTIONS} -f Dockerfile.debian --build-arg SETUP=1 --build-arg OPT_PDF=1 -t ${DOCKER_ORG}/gvm:debian-data-full .


.PHONY: build
build: build_latest build_full build_data build_data_full 

build_squash:
	cd ${PWD} ; \
	docker build --no-cache --squash --platform ${PLATFORM} ${ADD_OPTIONS} -t ${DOCKER_ORG}/gvm:no-data-uid-squash .
build_latest: 
	cd ${PWD} ; \
	docker build --platform ${PLATFORM} ${ADD_OPTIONS} -t ${DOCKER_ORG}/gvm:alpine -t ${DOCKER_ORG}/gvm:latest .
build_full: 
	cd ${PWD} ; \
	docker build --platform ${PLATFORM} ${ADD_OPTIONS} --build-arg OPT_PDF=1  -t ${DOCKER_ORG}/gvm:full .
build_data: 
	cd ${PWD} ; \
	docker build --platform ${PLATFORM} ${ADD_OPTIONS} --build-arg SETUP=1 -t ${DOCKER_ORG}/gvm:data .
build_data_full: 
	cd ${PWD} ; \
	docker build --platform ${PLATFORM} ${ADD_OPTIONS} --build-arg SETUP=1 --build-arg OPT_PDF=1 -t ${DOCKER_ORG}/gvm:data-full .
	
run-debian:
	sudo rm -rf ${PWD}/storage
	mkdir -p ${PWD}/storage/postgres-db
	mkdir -p ${PWD}/storage/openvas-plugins
	mkdir -p ${PWD}/storage/gvm
	mkdir -p ${PWD}/storage/ssh
	docker run --rm --publish 8080:9392 --publish 5432:5432 --publish 2222:22 \
	--env DB_PASSWORD="postgres DB password" \
	--env PASSWORD="webUI password" \
	--env SSHD="true" \
	${OPTIONS} \
	--volume "${PWD}/storage/postgres-db:/opt/database" \
	--volume "${PWD}/storage/openvas-plugins:/var/lib/openvas/plugins" \
	--volume "${PWD}/storage/gvm:/var/lib/gvm" \
	--volume "${PWD}/storage/ssh:/etc/ssh" \
	--name gvm ${DOCKER_ORG}/gvm:debian-latest

run-full:
	mkdir -p ${PWD}/storage/postgres-db
	mkdir -p ${PWD}/storage/openvas-plugins
	mkdir -p ${PWD}/storage/gvm
	mkdir -p ${PWD}/storage/ssh
	docker run --rm --publish 8080:9392 --publish 5432:5432 --publish 2222:22 \
	--env DB_PASSWORD="postgres DB password" \
	--env PASSWORD="webUI password" \
	--env SSHD="true" \
	--volume "${PWD}/storage/postgres-db:/opt/database" \
	--volume "${PWD}/storage/openvas-plugins:/var/lib/openvas/plugins" \
	--volume "${PWD}/storage/gvm:/var/lib/gvm" \
	--volume "${PWD}/storage/ssh:/etc/ssh" \
	--name gvm ${DOCKER_ORG}/gvm:data-
	
run-latest:
	mkdir -p ${PWD}/storage/postgres-db
	mkdir -p ${PWD}/storage/openvas-plugins
	mkdir -p ${PWD}/storage/gvm
	mkdir -p ${PWD}/storage/ssh
	docker run --rm --publish 8080:9392 --publish 5432:5432 --publish 2222:22 \
	--env DB_PASSWORD="postgres DB password" \
	--env PASSWORD="webUI password" \
	--env SSHD="true" \
	--volume "${PWD}/storage/postgres-db:/opt/database" \
	--volume "${PWD}/storage/openvas-plugins:/var/lib/openvas/plugins" \
	--volume "${PWD}/storage/gvm:/var/lib/gvm" \
	--volume "${PWD}/storage/ssh:/etc/ssh" \
	--name gvm ${DOCKER_ORG}/gvm:alpine