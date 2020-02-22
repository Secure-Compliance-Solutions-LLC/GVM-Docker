# A Greenbone Vulnerability Management 11 Docker Image

This docker image is based on GVM 11 but with a few package modifications. After years of successfully using the OpenVAS 8/9 package, maintained by the Kali project, we started having performance issues. After months of trying to tweak OpenVAS, with varying and short lived success, we decided to maintain our own packaged version of GVM 11. This was done to streamline the installation, cleanup, and improve reliability.

## Important Note

Currently the GVM reporting does not allow you to export reports containing more than 1000 lines. This is true for all report types. We have found a way around this limitation; however, it creates a problem with the webUI and the vulnerability data wont load in the browser. The solution we have, right now, is a script you will need to download and run. It will let you choose which container you'd like to patch and which patch you'd like to implement. If you "fix" the 1000 lines report exporting issue, it breaks the UI. Once you "fix" the UI reporting, you can no longer export more than 1000 lines in your reports. We will continue to work on a better solution, but for now, this does work.

To implement this fix, run the following command and choose from the patching options AFTER you finished the rest of the setup.
```bash
docker exec -it gvm bash -exec "/reportFix.sh"
```
Note: we have used the container name gvm to be consistent with the rest of the documentation. Modify the command accordingly.



## Deployment

**Install docker**

If you have Kali or Ubuntu you can use the docker.io package.
```shell
apt install docker.io
```

If you are using any debian based OS that does not have the docker.io package, you can follow [this guide](https://docs.docker.com/install/linux/docker-ce/debian/) 

You can also use the docker install script by running:
```bash
curl https://get.docker.com | sh
```

**Run our container**

This command will pull, create, and start the container:

Without persistent volume:

```shell
docker run --detach --publish 8080:9392 -e PASSWORD="Your admin password here" --name gvm securecompliance/gvm
```
With persistent volume:

```shell
docker run --detach --publish 8080:9392 -e PASSWORD="Your admin password here" --volume gvm-data:/data --name gvm securecompliance/gvm
```

You can use whatever `--name` you'd like but for the sake of this guide we're using gvm.

The `-p 8080:9392` switch will port forward `8080` on the host to `9392` (the container web interface port) in the docker container. Port `8080` was chosen only to avoid conflicts with any existing OpenVAS/GVM installation. You can change `8080` to any available port that you'd like.

Depending on your hardware, it can take anywhere from a few seconds to 10 minutes while the NVTs are scanned and the database is rebuilt. **The default admin user account is created after this process has completed. If you are unable to access the web interface, it means it is still loading (be patient).**

**Checking Deployment Progress**

There is no easy way to estimate the remaining NVT loading time, but you can check if the NVTs have finished loading by running:
```
docker logs gvm
```

If you see "Your GVM 11 container is now ready to use!" then, you guessed it, your container is ready to use.

## Accessing Web Interface

Access web interface using the IP address of the docker host on port 8080 - `http://<IP address>:8080`

Default credentials:
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
