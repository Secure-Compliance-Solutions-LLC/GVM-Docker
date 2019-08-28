# Openvas 10 Docker Image

This docker image is based on Openvas 10 but with a few package modifications. After years of using openvas8 and openvas9 on kali we started having issues running scans with the openvas package maintained by the kali project. We have decided to maintain our own build and streamline the installation and cleanup.


**Deployment**

Install docker (google is your friend) and run our container.

`docker run -d -p 8080:9392 securecompliance/openvas --name openvas`

You can use whatever --name you'd like at the end, but for the sake of this guide, we're keeping it simple to use as a reference.

This will pull the image from our docker repo and start it using port 8080 instead of 9392. Depending on your hardware, it can take anyhwere from a few seconds to 10 minutes while the NVTs are scanned and the database is rebuilt. The default user account is created after this process has completed. If you are unable to login, it means it is still loading. (be patient)

Access web interface using the IP address of the docker host system on port 8080 - `https://<IP address>:8080`

```
Username: admin
Password: admin
```

