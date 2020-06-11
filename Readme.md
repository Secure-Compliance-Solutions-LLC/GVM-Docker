# A Greenbone Vulnerability Management 11 Docker Image

This docker image is based on GVM 11 but with a few tweaks. After years of successfully using the OpenVAS 8/9 package, maintained by the Kali project, we started having issues. After months of trying to tweak OpenVAS, with varying and short lived success, we decided to maintain our own packaged version of GVM 11. This was done to streamline the installation, cleanup, and improve reliability.

## Table of contents

* [Quick Start](#quick-start)
* [How to use](#how-to-use)
  * [Accessing Web Interface](#accessing-web-interface)
* [All Environment Variables](all-environment-variables)

# Image tags

| Tag Name          | Description                             |
| ----------------- | --------------------------------------- |
| latest, master    | Latest dev version                      |
| {version}         | A specific version of the image         |
| scanner           | Scanner only image for remote scanning  |
| {version}-scanner | A specific version of the scanner image |
| upgrade-database  | For upgrading the postgres database     |

### Current versions

* 11.0.1-r1 (Postgres 12)

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

This command will pull, create, and start the container:

```shell
docker run --detach --publish 8080:9392 --env PASSWORD="Your admin password here" --volume gvm-data:/data --name gvm securecompliance/gvm:11.0.1-r1
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



## All Environment Variables

| Name     | Description                            | Default Value |
| -------- | -------------------------------------- | ------------- |
| USERNAME | Default admin username                 | admin         |
| PASSWORD | Default admin password                 | admin         |
| HTTPS    | If the web ui should use https vs http | true          |



## Upgrading

If you are upgrading from an older version of postgresql than the one you want to upgrade to. You will need to first upgrade the postgres database.

Before upgrading the database make sure the gvm container is stopped.

You can upgrade the database with this command:

```shell
docker run --tty --rm --volume gvm-data:/data --name temp securecompliance/gvm:upgrade-database
```

After upgrading the database or if you did not need to upgrade continue below.

Remove the old container with:

```shell
docker rm -f gvm
```

Create a new container with this command replacing {version} with the version you want:

```shell
docker run --detach --publish 8080:9392 --env PASSWORD="Your admin password here" --volume gvm-data:/data --name gvm securecompliance/gvm:{version}
```



## How to use

General information on using the image

### Accessing the web interface

Access web interface using the IP address of the docker host on port 8080 - `https://<IP address>:8080`

Default credentials:
```shell
Username: admin
Password: admin
```

### Monitoring scan progress

This command will show you the GVM processes running inside the container:
```shell
docker top gvm
```

### Checking the GVM logs

All the logs from /usr/local/var/log/gvm/* can be viewed by running:
```shell
docker logs gvm
```

### Updating the NVTs

The NVTs will update every time the container starts. Even if you leave your container running 24/7, the easiest way to update your NVTs is to restart the container.
```shell
docker restart gvm
```

### Change GVM report result limit

Currently the GVM reporting does not allow you to export reports containing more than 1000 lines. This is true for all report types. We have found a way around this limitation; however, it creates a problem with the webUI and the vulnerability data will take longer to load in the browser the higher you set the max rows. We have created a script that will allow you to set a custom rows per page value based on the size of your scan results. We have found that it isn't worth the hassle to try exporting reports with more than 15000 lines. 15000 seems to be the sweet spot that will usually work, provided you have enough RAM in the device used to access the web UI.

To implement this fix, run the following command AFTER you finished the rest of the setup.

```shell
docker exec -it gvm bash -exec "/reportFix.sh"
```

Note: we have used the container name gvm to be consistent with the rest of the documentation. Modify the command accordingly.

### Setup Remote scanner

TODO