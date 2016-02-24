# ALICE CVMFS Instructions

By: Raymond Ehlers (raymond.ehlers@yale.edu), Yale RHIG, Feb 2016. Thanks to James Mulligan, Salvatore Aiola, and Eliane Epple for suggestions and help in testing out the scripts and instructions.

These instructions will allow you to download and use compiled versions of Alien, Root, AliRoot, GEANT3, and Fastjet (+ contrib). With this approach, getting the latest version (or any version) of any piece of software is just a matter of running a few commands. When a library or executable is needed, it will be downloaded automatically. We can even compile AliPhysics using pre-built AliRoot packages!

These instructions will work for both Mac OS X and Linux.

There are two main work flows:

 - Use pre-built package(s) (for example, AliPhysics) and run over data. For more, see [here](#pre-built-packages).
 - Use pre-built package(s) (for example, AliRoot) and compile other code against it (for example, a local copy of AliPhysics). For more, see [here](#compile-your-own-code).

To establish terminology, this is achieved by using a Docker container. A container is roughly an operating system image that has been configured with software. In our case, I have created an image that allows us to use CVMFS. On Mac OS X, this container must run inside of a virtual machine, but all of this is transparent to the user, so the details are not important.

Before beginning, it is important to a few things to keep in mind:

 1. Initial access of a given file or executable can be a little slow. Be patient. This should only happen the first time you access the file for a given package (ie when you open `aliroot`). Once it is loaded, it will work as normal, and should be about as fast as normal.
 2. This setup requires network connectivity! You are pulling these pre-built packages dynamically so if your network connect is not great, then the performance may not be great. Of course, once the packages are downloaded, this should not be an issue.

Mac OS X Specific:

 3. We are sharing files over an internal network connection (`nfs`) to the Docker container. Consequently, it may be slightly slower than running everything natively. I have not noticed any performance issues so far, but I wouldn't recommend running something like a full train using this setup (not that I anticipate anyone would want to do that).

#### Table of Contents

 - [Prerequisites](#prerequisites)
     - [Mac OS X](#mac-os-x-prerequisites)
     - [Linux](#linux-prerequisites)
 - [Pre-Built Packages](#pre-built-packages)
 - [Compile Your Own Code](#compile-your-own-code)
 - [`startDocker.sh` User Configuration](#startdocker.sh-user-configuration)
 - [Usage Instructions](#usage-instructions)
     - [Usage Notes](#usage-notes)
     - [CVMFS Instructions](#cvmfs-instructions)
 - [Troubleshooting](#troubleshooting)
     - [General](#general-troubleshooting)
     - [Mac OS X Specific](#mac-os-x-specific-troubleshooting)
         - [`docker-machine-nfs` Specific](#docker-machine-nfs-troubleshooting)
 - [Technical Details](#technical-details)
     - [`startDocker.sh` Script](#startdocker.sh-script)
     - [Script Details](#script-details)

## Prerequisites

0. **Make a backup!** Everything should be perfectly fine, but it's a good idea to be safe.

#### Mac OS X Prerequisites

1. `docker-machine`. Install via:
    ```
    $ brew cask install dockertoolbox
    ```
2. [`docker-machine-nfs`](https://github.com/adlogix/docker-machine-nfs). From the documentation, use:
    ```
    $ curl -s https://raw.githubusercontent.com/adlogix/docker-machine-nfs/master/docker-machine-nfs.sh |
      sudo tee /usr/local/bin/docker-machine-nfs > /dev/null && \
      sudo chmod +x /usr/local/bin/docker-machine-nfs
    ```
3. Create a docker-machine VM named `default`. Note that this will only use the space actually required to store the VM, growing up to 30 GB total. The initial size when everything is setup is approximately 2 GB.
    ```
    $ docker-machine create --driver virtualbox --virtualbox-disk-size "30000" default
    ```

4. (Recommended) Remove Docker files from Time Machine. These files change very frequently and are very easy to recreate. Go to the Time Machine settings, click options, and then exclude `~/.docker/machine/machines`. When adding the folder, you may need to click on options to show hidden files.

#### Linux Prerequisites
1. `docker`. See [here](https://docs.docker.com/linux/step_one/). Roughly, the instructions are to use:
```
$ curl -fsSL https://get.docker.com/ | sh
```

## Pre-Built Packages

The work flow here is to load pre-built package(s) and run them. For example, one could download a test train, load the tag via CVMFS, and then test the train against that tag. You could also build against the packages if you have code that depends on AliRoot or AliPhysics (for building AliPhysics, see [below](#compile-your-own-code)).

0. Install the [prerequisites](#prerequisites) for your platform.
1. Start Docker and make your $HOME directory available to the Docker container. If necessary, other folders can be made available in the [user configuration](#startdocker.sh-user-configuration).
```
$ ./startDocker.sh
```
2. We are now inside of the image, so the prompt should have changed. Now just configure CVMFS:
```
# Your output should look very similar
> source setupAliceEnv.sh
Warning: autofs service is not running
Warning: failed to use Geo-API with cvmfs.racf.bnl.gov
CernVM-FS: running with credentials 498:497
CernVM-FS: loading Fuse module... done
CernVM-FS: mounted cvmfs on /cvmfs/alice.cern.ch
```

You can now use CVMFS! See the [usage instructions](#usage-instructions). If you need more advanced options, see the [user configuration](#startdocker.sh-user-configuration).

## Compile Your Own Code

The work flow here is that you develop in your normal install of AliPhysics on your system (ie that you installed via the automatic or manual installation instructions). Once you are done developing, you load all of the dependencies in CVMFS, compile in the Docker container, and then you work as normal (test, run over data, etc). If you need to make changes to your code, you can edit the file either in 

Note: If your code is stand-alone from packages (ie. If it is not contained in a package, such that you would need to recompile it), then you can just use the method [above](#pre-built-packages).

### Setup AliPhysics and the ALICE environment

These steps only need to be performed once, although steps 2 and 3 will need to be edited if you are using a different AliPhysics version or repeated if you change AliPhysics versions.

1. Install AliPhysics and all prerequisites on your system. Use Dario's instructions.
2. Add the following lines to your `alice-env.conf` file. Note the AliTuple array value (here it is 3) must be continuous within your `alice-env.conf` file.
```
# Must be run after loading an environment from alienv on CVMFS!
AliTuple[3]="alien=${ALIEN_RUNTIME_ROOT} \
             root=${ROOTSYS} \
             fastjet=${FASTJET} \
             geant3=${GEANT3_ROOT} \
             aliroot=${ALICE_ROOT} \
             aliphysics=dockerMaster(master)"
```
3. To ensure that you do not overwrite the build on your local machine, make sure so set a build folder, which in the above example is `dockerMaster` (the AliPhysics version is in parenthesis). To create this folder, run
```
$ git-new-workdir "${ALICE_PREFIX}/aliphysics/git" "$(dirname "$ALICE_PHYSICS")/src"
```

### Compiling Inside of the Docker Container

1. Start Docker and make your $HOME directory available to the Docker container. If necessary, other folders can be made available in the [user configuration](#startdocker.sh-user-configuration).
```
$ ./startDocker.sh
```
2. We are now inside the image, so the prompt should have changed. Now configure CVMFS. For CVMFS usage information, see [here](#cvmfs-instructions).
```
# Your output should look very similar
$ source setupAliceEnv.sh
Warning: autofs service is not running
Warning: failed to use Geo-API with cvmfs.racf.bnl.gov
CernVM-FS: running with credentials 498:497
CernVM-FS: loading Fuse module... done
CernVM-FS: mounted cvmfs on /cvmfs/alice.cern.ch
$ alienv enter # AliRoot Version
```
3. Setup the ALICE environment.
```
$ cd $ALICE_PREFIX
$ source alice-env.sh
```
4. Run CMake and compile.
```
# Create the directory and move to it
$ mkdir -p "$(dirname "$ALICE_PHYSICS")/build" && cd "$_"
# CMake and compile. cmakeCommand is listed below in the useful commands section.
$ eval $cmakeCommand
$ make install
```

Done! See the [usage instructions](#usage-instructions) and the [useful commands](#useful-commands) section below. If you need more advanced options, see the [user configuration](#startdocker.sh-user-configuration).

### Useful Commands

A number of variable are defined in the container for convenience. Additional variables can be set by the user. See the [user configuration](#startdocker.sh-user-configuration).

 - `$ALICE_PREFIX` is set if you loaded the ALICE environment on your local machine before running the `startDocker.sh` script. Otherwise, it automatically be set to "$HOME/alicesw", as `$ALICE_PREFIX`is often set to this value.
 - `$cmakeCommand` is set to the cmake command for AliPhysics so that you do not need to copy and paste. Use it with `eval $cmakeCommand`. The specific command (as of Feb 2016) is
```
cmake "$(dirname "$ALICE_PHYSICS")/src" -DCMAKE_INSTALL_PREFIX="$ALICE_PHYSICS" -DCMAKE_C_COMPILER=`root-config --cc` -DCMAKE_CXX_COMPILER=`root-config --cxx` -DCMAKE_Fortran_COMPILER=`root-config --f77` -DALIEN="$ALIEN_DIR" -DROOTSYS="$ROOTSYS" -DFASTJET="$FASTJET" -DCGAL="$CGAL_ROOT" -DALIROOT="$ALICE_ROOT" -DCMAKE_BUILD_TYPE=RELWITHDEBINFO 
```

## `startDocker.sh` User Configuration

Advanced options can be configured in the `userConfig.conf` file. This includes:

- Environmental variables to be available in the container.
- Folders to be available in the container.
- Additional arguments to `docker run`.

Further even more advanced variables are also availble. Please see the file for extensive documentation.

## Usage Instructions

### Usage Notes

- Only files that are saved in directories that have been made available from your system (for example, your $HOME directory) will be saved once you have exited the Docker container! If you can't access the file outside of the container, then you it will be lost when you exit!

### CVMFS Instructions

Usage of CVMFS is well documented on [Dario's Page](https://dberzano.github.io/alice/install-aliroot/cvmfs/#use_aliroot_from_cvmfs). The first line in his instructions (the `source` command) has already been performed by our ALICE setup script.

However, there is one undocumented option that is worth noting - the `archive` option. Archived packages can be used by passing the `-a` or `--archive` option to `alienv`. This allows the use of older packages, including ones that may not be available on the grid.

Further undocumented options can be found by opening the `alienv` script, which is located at `/cvmfs/alice.cern.ch/bin/alienv`. It can be easily accessed by passing `$(which alienv)` to your favorite text editor. Given that these options are undocumented, they are likely only useful for limited cases.

## Troubleshooting

### General Troubleshooting

 - If you run into issue with CMake being unable to find AliRoot, there are two possible solutions:
     - Move to the `build` directory and remove the `CMakeFiles` directory and `CMakeFiles.txt`, then run CMake again.
     - If that does not work, then the `build` directory needs to be removed. This means that the entire package needs to be rebuilt.
 - If there are `libexpat.so` errors, it is related to GEANT. It likely means you have the wrong version! If you run into other issues with `cmake`, you have two options. You can try to remove `CMakeCache.txt` and the `CMakeFiles` folder and try again, but this is not guaranteed to work. Alternatively, you will need to remove the build folder and try again. Note that this will remove any compilation progress that you have made.

### Mac OS X Specific Troubleshooting

 - If you see errors about clock skew in `make`, you should run make again after your initial `make` finishes. This is caused by the way that files are shared via `nfs`. Running make again should update the build in case any files were missed. (In testing, the files that had clock skews did not appear to be source files which would have mattered for the build. They were just configuration files. However, it is still a good idea to pay attention to these types of errors).
 - If you connect to Cisco AnyConnect (ie for the Yale VPN), it will probably break the network routing until you restart. Based on the available information, [this](https://github.com/boot2docker/boot2docker/issues/628#issuecomment-148961252) should resolve the issue, but I have not tested it yet. Note that boot2docker is the old name for what we are using now.

#### `docker-machine-nfs` Troubleshooting

 - If `docker-machine-nfs` has trouble with the `/etc/exports` file, it can often be solved by (re)moving the file and allowing it to start from scratch. As long as you do not use `nfs` to share files outside of this process, there are no problems with starting over. To try this approach, backup the file
```
$ sudo mv /etc/exports /etc/exports.bak
```
   Then run `./startDocker.sh` again. If the issue is resolved and you don't use `nfs` elsewhere, you can delete this file. If the issue is not resolved, you can restore the backup if you desire (although a newly generated configuration should be fine, so it is likely not necessary).
 - If you add a directory in `userConfig.conf` and `docker-machine-nfs` claims to have mounted it, but it is not accessible in the contianer, then change `forceNFSReconfiguration` to `true` in `userConfig.conf` and try again. Once the issue is resolved, be certain to change it back to `false`!

## Technical Details

If you are a regular user, you probably do not need to read past here. The section describes the details of how this process works and why decisions were made, so it is only relevant for advanced users.

### `startDocker.sh` Script 

This script was created to vastly simplify all of the setup. Different approaches are required on Linux (normal docker) and Mac OS X (boot2docker + NFS), but this script allows us to use the approach on both systems. The operations that the script preforms are described below.

#### TL;DR

These operations are explained below.

Mac OS X:
```
$ docker-machine start default
$ eval "$(docker-machine env default)"
# Only if necessary
$ docker volume create --name cvmfsCache
$ docker-machine-nfs --shared-folder="$HOME"
# Only once every week
$ docker pull rehlers/alice-cvmfs:latest
# Will include any additional arguments specified by the user
$ docker run -it --rm --privileged -v cvmfsCache:/cvmfsCache -e "LOCAL_USER_ID=$(id -u $USER)" rehlers/alice-cvmfs:latest /bin/bash
```

Linux: 
```
# Only if necessary
$ docker volume create --name cvmfsCache
# Only once every week
$ docker pull rehlers/alice-cvmfs:latest
# Will include any additional arguments specified by the user
$ docker run -it --rm --privileged -v cvmfsCache:/cvmfsCache -e "LOCAL_USER_ID=$(id -u $USER)" rehlers/alice-cvmfs:latest /bin/bash
```

### Script Details

#### Sharing Files

##### Mac OS X

We use `nfs` to share files because VirtualBox or VMWare file sharing is rather slow. `docker-machine-nfs` shares host files over `nfs` to the container. This script is very useful because it takes a complicated process and seems to make it very easy.

Note that `nfs` maps all files created in the container to the host user's user id and group, regardless of who or how the file was created.

##### Linux

Sharing files with the host is natively supported in Docker. However, the user id (uid) of the user in the Docker container does not match that of your user. So any files created in the Docker container would not have the proper permissions. Consequently, we need to change the uid of the container.

This approach is outline [here](https://denibertovic.com/posts/handling-permissions-with-docker-volumes/). It explains it in detail, but roughly, we pass the uid of the host user to the container, which then creates a new user and switches to it. Note that this process is not required for Mac OS X, since `nfs` remaps the uid (see above), but it also doesn't hurt, and it allows for a consistent approach (otherwise we would likely need a different image for each platform).

Note that in principle user namespaces are perfectly suited for this issue. However, there are a few problems:

1. User namespaces are not compatible with privileged containers, which are required for the way that CVMFS is currently mounted.
2. The sub uids don't map in the host correctly. So the permissions still seem wrong. For more information, see (for example) [here](https://stackoverflow.com/q/35291520).

These may be resolved quickly, but they are still very new in Docker as of Feb 2016, so there is not a tremendous amount of information about them yet.

#### Docker Volume

We want to store the CVMFS data persistently to save time on cached data. This command will store the data persistently in what Docker calls volumes. The CVMFS cache is set to uset at most 16.5 GB (15 GB + 10% for overhead).

```
# The CVMFS data will be cached so that it will run faster
$ docker volume create --name cvmfsCache
```

#### Docker Pull

By default, the image would never be updated. The script stores when it last checked for images and then checks approximately weekly. This ensure that any changes that are pushed to the image are distributed in a timely manner.

It runs
```
$ docker pull rehlers/alice-cvmfs:latest
```

#### Docker Run

Start the Docker image with `docker run`. With that command, we mount our cvmfs data cache volume, as well as share the specified folders. Lastly, we tell it the image to use and what to start (namely, a `bash` shell). **Note that any files that you create inside of the Docker image that are not inside of the specified shared folders will be lost when you exit the Docker image.**

```
# Configure docker
$ eval "$(docker-machine env default)"
$ docker run -it --rm --privileged -v cvmfsCache:/cvmfsCache -e "LOCAL_USER_ID=$(id -u $USER)" rehlers/alice-cvmfs:latest /bin/bash
```

The options are:

 - `-it` makes the container interactive. Otherwise, we would have to access it over ssh, which would be more complicated.
 - `--rm` deletes the container when it is exited, which is the Docker convention.
 - `--privileged` allows the container to use fuse, which is required to mount directories with CVMFS. This could be avoided by mounting the directories in the host operating system, but this gets messy and would likely be slower on Mac OS X (since it has to mount over `nfs`), so it is not currently the preferred option.
 - `-v` mounts volumes. It is used to mount the CVMFS cache, as well as the host folders.
 - `-e` sets a number of variables in the container. `$LOCAL_USER_ID` must contain the uid of the local user so that using files from the host is configured correctly.

The image is derived from the Dario's aliSW Scientific Linux 6 image used on the build servers. A number of pieces of software are added and updates are applied. It is extremely likely that the image could be substantially shrunk if someone was willing to put in the time. However, it does not seem worthwhile at the moment.
