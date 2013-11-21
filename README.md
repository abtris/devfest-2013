# Devfest-2013


DevFest.cz 2013 Docker.io demos

## Docker Best Practices

Build from Dockerfile

The only sane way to put together a dev environment in Docker is to use raw Dockerfile and a private repository. Pull from the central docker registry only if you must, and keep everything local.

Chef recipes are slow

You might think to yourself, “self, I don’t feel like reinventing the wheel. Let’s just use chef recipes for everything.”

The problem is that creating new containers is something that you’ll do lots. Every time you create a container, seconds will count, and minutes will be totally unacceptable. It turns out that calling apt-get update is a great way to watch nothing happen for a while.

### Use raw Dockerfile

Docker uses a versioned file system called AUFS, which identifies commands it can run from layers (aka cached fs) and pulls out the appropriate version. You want to keep the cache happy. You want to put all the mutable stuff at the very end of the Dockerfile, so you can leverage cache as much as possible. Chef recipes are a black box to Docker.

The way this breaks down is:

    Cache wins.
    Chef, ansible, etc, does not use cache.
    Raw Dockerfile uses cache.
    Raw Dockerfile wins.

There’s another way to leverage Docker, and that’s to use an image that doesn’t start off from ubuntu or basebox. You can use your own base image.

### The Basics

Install a internal docker registry

Install an internal registry (the fast way) and run it as a daemon:

    docker run -name internal_registry -d -p 5000:5000 samalba/docker-registry

Alias server to localhost:

    echo "127.0.0.1      internal_registry" >> /etc/hosts

Check internal_registry exists and is running on port 5000:

    apt-get install -y curl
    curl --get --verbose http://internal_registry:5000/v1/_ping
    
### Install Shipyard

Shipyard is a web application that provides an easy to use interface for seeing what Docker is doing.

Open up a port in your Vagrantfile:

    config.vm.network :forwarded_port, :host => 8005, :guest => 8005
    
Install shipyard from the central index:

    SHIPYARD=$(docker run \
        -name shipyard \
      -p 8005:8000 \
      -d \
      shipyard/shipyard)

You will also need to replace /etc/init/docker.conf with the following:


    description "Docker daemon"

    start on filesystem and started lxc-net
    stop on runlevel [!2345]

    respawn

    script
            /usr/bin/docker -d -H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock
    end script
    
THen reboot the VM.

Once the server has rebooted and you’ve waited for a bit, you should have shipyard up. The credentials are “shipyard/admin”.

Go to http://localhost:8005/hosts/ to see Shipyard’s hosts.
In the vagrant VM, ifconfig eth0 and look for “inet addr:10.0.2.15” — enter the IP address.

### Create base image

Create a Dockerfile with initialization code such as `apt-get update / apt-get install’ etc: this is your base.
Build your base image, then push it to the internal registry with docker build -t internal_registry:5000/base .
Build from your base image

Build all of your other Dockerfile pull from “base” instead of ubuntu.

Keep playing around until you have your images working.

### Push your images

Push all of your images into the internal registry.

### Save off your registry

if you need to blow away your Vagrant or set someone else up, it’s much faster to do it with all the images still intact:

    docker export internal_registry > internal_registry.tar
    gzip internal_registry.tar
    mv internal_registry.tar.gz /vagrant
