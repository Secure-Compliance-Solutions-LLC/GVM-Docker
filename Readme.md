# Openvas 10 Docker Image

This docker image is based on Openvas 10 but with a few package modifications. After years of using openvas8 and openvas9 on kali we started having issues running scans with the openvas package maintained by the kali project. We have decided to maintain our own build and streamline the installation and cleanup.


## Deployment

Install docker (google is your friend) and run our container.
```
docker run -d -p 8080:9392 securecompliance/openvas --name openvas
```
You can use whatever `--name` you'd like but for the sake of this guide we're keeping it simple.

This will pull the image from our docker repo and port forwarding 9392 (OpenVAS default web interface) to 8080 to make it accessible on the host IP. Depending on your hardware, it can take anyhwere from a few seconds to 10 minutes while the NVTs are scanned and the database is rebuilt. The default user account is created after this process has completed. If you are unable to login, it means it is still loading. (be patient)

**Checking Deployment Progress**

There is no easy way to estimate the remaining NVT loading time, but you can check if the NVTs have finished loading by running 
```
docker logs openvas
```

If you see "Your OpenVAS container is now ready to use!" then, you guessed it, your container is ready to use.

## Accessing Web Interface

Access web interface using the IP address of the docker host on port 8080 - `https://<IP address>:8080`

```
Username: admin
Password: admin
```

## Monitoring Scan Progress

This command will show you the running OpenVAS processes in the container
```
docker top openvas
```

## Checking the OpenVAS Logs

We are tailing all the logs from /usr/local/var/log/gvm/*
You can view them by running
```
docker logs openvas
```

## Updating the NVTs
The NVTs will update every time the container starts. If you leave your container running 24/7, you will need to periodically update the NVTs using the following commands:
```
docker exec -it openvas bash
```
Once inside the container run:
```
greenbone-nvt-sync
openvasmd --rebuild --progress
greenbone-certdata-sync
greenbone-scapdata-sync
openvasmd --update --verbose --progress
/etc/init.d/openvas-manager restart
/etc/init.d/openvas-scanner restart
```

