# Greenbone Vulnerability Stack Docker Image

[![Docker Pulls](https://img.shields.io/docker/pulls/securecompliance/gvm.svg)](https://hub.docker.com/r/securecompliance/gvm/)
[![Docker Stars](https://img.shields.io/docker/stars/securecompliance/gvm.svg)](https://hub.docker.com/r/securecompliance/gvm/)
[![Gitter](https://badges.gitter.im/Secure-Compliance-Solutions-LLC/gvm-docker.svg)](https://gitter.im/Secure-Compliance-Solutions-LLC/gvm-docker)

This docker image is based on Greenbone Vulnerability Management 11. This Docker image was developed to help steamline, cleanup, and improve reliability of the components of the Greenbone Vulnerability stack (Which includes OpenVAS).

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

## Quick start

### Install docker

If you have a Debian-Based Operating System you can use the docker.io package.
```console
apt install docker.io
```

> If you are using a docker supported OS that does not have the docker.io package, you should take a look at [this page](https://docs.docker.com/engine/install/).

You can also use the docker install script by running:
```console
curl https://get.docker.com | sh
```

### Runing the container

This command will pull, create, and start the container: (replace {version} with the version you want)

```console
docker run --detach --publish 8080:9392 --env PASSWORD="Your admin password here" --volume gvm-data:/data --name gvm securecompliance/gvm:{version}
```


## Wiki Table of contents
* [Components of the Greenbone Vulnerability Stack](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Components-of-the-Greenbone-Vulnerability-Stack)
* [GVM Environment Variables](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/GVM-image-Environment-Variables)
* [Scanner image Environment Variables](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Scanner-image-Environment-Variables)
* [GVM image Ports](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/GVM-image-Ports)
* [Image tags](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Image-tags)
* [Upgrading](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Upgrading)
* [Runing the container (Additional)](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Runing-the-container-(Additional))
* [Checking Deployment Progress](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Checking-Deployment-Progress)
* [Accessing Web Interface](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Accessing-Web-Interface)
* [Change GVM report result limit](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Change-GVM-report-result-limit)
* [Checking the GVM logs](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Checking-the-GVM-logs)
* [Monitoring scan progress](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Monitoring-scan-progress)
* [Updating the NVTs](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Updating-the-NVTs)
* [Setup Remote scanner](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/wiki/Setup-Remote-scanner)

