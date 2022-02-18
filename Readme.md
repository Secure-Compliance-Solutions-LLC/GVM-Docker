[![Docker Pulls](https://img.shields.io/docker/pulls/securecompliance/gvm.svg)](https://hub.docker.com/r/securecompliance/gvm/)
[![Docker Stars](https://img.shields.io/docker/stars/securecompliance/gvm.svg)](https://hub.docker.com/r/securecompliance/gvm/)
[![Gitter](https://badges.gitter.im/Secure-Compliance-Solutions-LLC/gvm-docker.svg)](https://gitter.im/Secure-Compliance-Solutions-LLC/gvm-docker)
[![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://github.com/ellerbrock/open-source-badges/)




Feature Requests Ideas [Click Here](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/discussions/categories/feature-request)

![](https://i.imgur.com/xNlUgCJ.png)

1. Please read these [DIRECTIONS](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/discussions/193) if you would like to be assign issues to work on
2. Please read the [PULL REQUEST POLICY](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/blob/master/PULL-REQUEST-POLICY.md)
3. Here is a list of [MILESTONES](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/milestones) to work on.

![Greenbone Vulnerability Management with OpenVAS](https://github.com/SCS-Labs/Images/raw/main/scs-gvm.png)


This setup is based on Greenbone Vulnerability Management and OpenVAS. We have made improvements to help stability and functionality.

You want to send GVM/OpenVAS results to Elasticsearch, try our [GVM Logstash project](https://github.com/Secure-Compliance-Solutions-LLC/gvm-logstash).

## Documentation
* [View our detailed instructions on gitbook](https://securecompliance.gitbook.io/projects/openvas-greenbone-deployment-full-guide)

If you would like something added to the documentation please create a issue [GVM-Docker Gitbook Repo](https://github.com/Secure-Compliance-Solutions-LLC/gitbook/issues)

## Quick Start

- Now all `-data` images are full pre-initialized (with available data from the build time)

> Pre Initialized (-data) images, have a web ui password: `adminpassword` and should be changed after the deployment. Also the Postgres got a default password: `none`

### Github Registry

```
docker pull ghcr.io/secure-compliance-solutions-llc/gvm-docker:debian-master-data-full
docker pull ghcr.io/secure-compliance-solutions-llc/gvm-docker:debian-master-data
docker pull ghcr.io/secure-compliance-solutions-llc/gvm-docker:debian-master-full
docker pull ghcr.io/secure-compliance-solutions-llc/gvm-docker:debian-master
```


### Docker Hub

> **NOTE**: Please do not use `docker pull securecompliance/gvm:latest`

```
docker pull securecompliance/gvm:debian-master-data-full
docker pull securecompliance/gvm:debian-master-data
docker pull securecompliance/gvm:debian-master-full
docker pull securecompliance/gvm:debian-master
```

## Estimated Hardware Requirements

| Hosts              | CPU Cores     | Memory    | Disk Space |
| :----------------- | :------------ | :-------- | :--------- |
| 512 active IPs     | 4@2GHz cores  | 8 GB RAM  | 30 GB      |
| 2,500 active IPs   | 6@2GHz cores  | 12 GB RAM | 60 GB      |
| 10,000 active IPs  | 8@3GHz cores  | 16 GB RAM | 250 GB     |
| 25,000 active IPs  | 16@3GHz cores | 32 GB RAM | 1 TB       |
| 100,000 active IPs | 32@3GHz cores | 64 GB RAM | 2 TB       |


## Architecture

The key points to take away from the diagram below, is the way our setup establishes connection with the remote sensor, and the available ports on the GMV-Docker container. You can still use any add on tools you've used in the past with OpenVAS on 9390. One of the latest/best upgrades allows you connect directly to postgres using your favorite database tool. 

![GVM Container Architecture](https://securecompliance.co/wp-content/uploads/2020/11/SCS-GVM-Docker.svg)


## About

We will do our best to conduct all development openly by documenting features and requirements, and managing the project using [issues](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/issues), [milestones](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/milestones), and [projects](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/projects).

<!--
## Dashboard - Sneak peak at our upcoming kibana dashboards

Soon we will release instructions on connecting your OpenVAS vulnerability details to elastic to create dashboards that are interactive and actually work. 

Below is a preview of what we're working on.
![Sneak Peak](https://securecompliance.co/wp-content/uploads/2020/11/dashboard.png)
-->
