# Docker Build Instructions

## Note

**You should only continue reading this document if you know exactly what you are doing and have a very good reason to be reading it. If not, this file is not for you! Go back to the main README file! You have been warned!**

This document is only needed if you are trying to rebuild the docker image that is used for the alice cvmfs instructions. This is __NOT__ normally something that has to be done. This is only necessary if changes are made to the setup scripts which should be fairly unlikely.

## Instructions

This docker image is built the same as any other normal image. It depends on the [`alisw/slc6-builder`](https://hub.docker.com/r/alisw/slc6-builder/) image that is maintained by Dario. To build an image called alice-cvmfs (as named in the instructions), simply run:

```
$ docker built -t alice-cvmfs .
```

Once this image is built, it can be used locally by selecting alice-cvmfs as the image. If you want to use it elsewhere, it must be tagged to upload. One must run:

```
# Find the tag of the build
$ docker images
# Tag it
$ docker tag <containerID> <username>/alice-cvmfs:latest
```

Next, login to docker hub with:

```
$ docker login --username=<username> --email=<email address>
```

It will prompt you for your password, so you will then need to login. Lastly, push the image

```
$ docker push <username>/alice-cvmfs
```

If you have rebuilt the image, be sure to change the image name in the instructions as appropriate.
