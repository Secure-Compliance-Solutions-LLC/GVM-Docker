# GreenBone Vulnerability Management 11 Docker Image

This docker image is based on GVM 11 but with a few package modifications. 
After years of successfully using the OpenVAS 8/9 package, maintained by the Kali project, we started having performance issues. After months of trying to tweak OpenVAS, with varying and short lived success, we decided to maintain our own modified version of GVM 11. This was done to streamline the installation, cleanup, and improve reliability.

See: https://community.greenbone.net/t/gvm-11-stable-initial-release-2019-10-14/3674

## Deployment

**Install docker**

If you have Kali or Ubuntu you can use the docker.io package.
```
apt install docker.io
```

If you are using any debian based OS that does not have the docker.io package, you can follow [this guide](https://docs.docker.com/install/linux/docker-ce/debian/) 

You can also use the docker install script by running:
```
curl https://get.docker.com | sh
```
**Build image**

You can build the docker image locally using this command:
```
 docker build --tag your-org/gvm:11.0.0 .
```

**Run our container**

This command will pull, create, and start the container:
```
docker run -d -p 8080:9392 -v /your_gvm_directory/pgdata:/pgdata:z -v /your_gvm_directory/pglog:/pglog:z --name gvm your-org/gvm:11.0.0
```
You can use whatever `--name` you'd like but for the sake of this guide we're using gvm.

The `-p 8080:9392` switch will port forward `8080` on the host to `9392` (the default web interface port) in the docker container. Port `8080` was chosen only to avoid conflicts with any existing installation. You can change `8080` to any available port that you'd like.

The `/your_gvm_directory` is where the database files will be stored if persistence storage is needed.
This directory need to be owned by user 102 and group 103

Depending on your hardware, it can take anyhwere from a few seconds to 10 minutes while the NVTs are scanned and the database is rebuilt. **The default user account is created after this process has completed. If you are unable to login, it means it is still loading (be patient).**

**Checking Deployment Progress**

There is no easy way to estimate the remaining NVT loading time, but you can check if the NVTs have finished loading by running:
```
docker logs gvm
```

If you see "Your gvm container is now ready to use!" then, you guessed it, your container is ready to use.

## Accessing Web Interface

Access web interface using the IP address of the docker host on port 8080 - `https://<IP address>:8080`

```
Username: admin
Password: admin
```

## Monitoring Scan Progress

This command will show you the GVM processes running inside the container:
```
docker top gvm
```

## Checking the GVM Logs

All the logs from /usr/local/var/log/gvm/* can be viewed by running:
```
docker logs gvm
```

## Updating the NVTs

The NVTs will update every time the container starts. Even if you leave your container running 24/7, the easiest way to update your NVTs is to restart the container.
```
docker restart gvm
```
