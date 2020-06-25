# Greenbone Vulnerability Stack Docker Image

[![Docker Pulls](https://img.shields.io/docker/pulls/securecompliance/gvm.svg)](https://hub.docker.com/r/securecompliance/gvm/) 
[![Docker Stars](https://img.shields.io/docker/stars/securecompliance/gvm.svg)](https://hub.docker.com/r/securecompliance/gvm/) 

This docker image is based on Greenbone Vulnerability Management 11. This Docker image was developed to help steamline, cleanup, and improve reliability of the components of the stack from 
- (1) Greenbone Security Assistant which it connects to the Greenbone Vulnerability Manager (GVM), which provides a full-featured user interface for vulnerability management and; 
- (2) Open Vulnerability Assessment Scanner (OpenVAS), which it is used for the Greenbone Security Manager appliances and is a full-featured scan engine that executes a continuously updated and extended feed of Network Vulnerability Tests (NVTs) and; 
- (3) the Greenbone Vulnerability Manager, which is the central management service between security scanners and the user clients, it manages the storage of any vulnerability management configurations and of the scan results. Access to data, control commands and workflows is offered via the XML-based Greenbone Management Protocol (GMP). Controlling scanners like OpenVAS is done via the Open Scanner Protocol (OSP).

|       Stack Component                           | Version |
|-------------------------------------------------|---------|
|Greenbone Vulnerability Manager                  |v9.0.1   |
|Greenbone Security Assistant                     |v9.0.1   |
|Open Vulnerability Assessment Scanner            |v7.0.1   |
|Greenbone Vulnerability Management Libraries     |v11.0.1  |
|ospd-openvas                                     |v1.0.1   |
|GVM Tools (Remote control your(GVM))             |v2.1.0   |
|SMB module for OpenVAS Scanner                   |v1.0.5   |
|Greenbone Vulnerability Management Python Library|v1.6.0   |
|Open Scanner Protocol daemon                     |v2.0.1   |


**GVM Architecture**

![GVM Stack Diagram](https://www.greenbone.net/wp-content/uploads/gse-gvm-10-architecture.png)

### Current GVM Versions

* 11.0.1-r3 (Postgres 12)

### Current Scanner Versions

* 7.0.1-r1

## Quick start

**Install docker**

If you have Kali or Ubuntu you can use the docker.io package.
```bash
apt install docker.io
```

If you are using a docker supported OS that does not have the docker.io package, you should take a look at [this page](https://docs.docker.com/engine/install/).

You can also use the docker install script by running:
```bash
curl https://get.docker.com | sh
```

**Runing the container**

This command will pull, create, and start the container: (replace {version} with the version you want)

```shell
docker run --detach --publish 8080:9392 --env PASSWORD="Your admin password here" --volume gvm-data:/data --name gvm securecompliance/gvm:{version}
```

You can use whatever `--name` you'd like but for the sake of this guide we're using gvm.

The `-p 8080:9392` switch will port forward `8080` on the host to `9392` (the container web interface port) in the docker container. Port `8080` was chosen only to avoid conflicts with any existing OpenVAS/GVM installation. You can change `8080` to any available port that you'd like.

Depending on your hardware, it can take anywhere from a few seconds to 10+ minutes while the NVTs are scanned and the database is rebuilt. **The default admin user account is created after this process has completed. If you are unable to access the web interface, it means it is still loading (be patient).**

**Checking Deployment Progress**

There is no easy way to estimate the remaining NVT loading time, but you can check if the NVTs have finished loading by running:
```shell
docker logs gvm
```

If you see "Your GVM 11 container is now ready to use!" then, you guessed it, your container is ready to use.


## Table of contents
* [GVM Environment Variables](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/GVM-image-Environment-Variables)
* [Scanner image Environment Variables](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Scanner-image-Environment-Variables)
* [GVM image Ports](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/GVM-image-Ports)
* [Image tags](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Image-tags)
* [Upgrading](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Upgrading)
* [How to use](#how-to-use)
* [Accessing Web Interface](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Accessing-Web-Interface)
* [Change GVM report result limit](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Change-GVM-report-result-limit)
* [Checking the GVM logs](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Checking-the-GVM-logs)
* [Monitoring scan progress](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Monitoring-scan-progress)
* [Updating the NVTs](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Updating-the-NVTs)
* [Setup Remote scanner](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Setup-Remote-scanner)

