---
tags: 
 - tutorials
date: 2013-07-21 13:30:00
title: How to compile and install Eucalyptus 3.3.0 on Ubuntu 13.04 from Github sources (cloud-in-a-box)
permalink: eucalyptus-3.3
---


This is an updated guide on how to build and install Eucalyptus 3.3.0 on
Ubuntu 13.04. I have tested these steps on a freshly installed & updated
Ubuntu 13.04 machine on Sunday, July 21st, 2013. There is another guide
[here](/eucalyptus-3.2/)
for Eucalyptus 3.2 and Ubuntu 12.04. :)

## Prerequisites

-   A Linux-capable machine with virtualization extensions
-   Space on your disk to install Ubuntu 13.04
-   More than 30GB of free space in `/var/lib/eucalyptus`. I had one
    67GB root partition with 45GB free. Please note that not having
    sufficient free space on the Node Controller (NC) machine will
    prevent you from launching instances with a
    `"Not enough resources (0 in default 1): vm instances"` message.

**WARNING:** Please, as you follow this guide, copy and paste one command
at a time, or type them by hand. Copying multiple commands at a time
might lead to some of the commands not being executed.

## Step 0: Download & install Ubuntu 13.04 on your system

You can find an x86\_64 version of Ubuntu 13.04 here:
[http://www.ubuntu.com/download/desktop](http://www.ubuntu.com/download/desktop)
Install, then boot into your fresh installation!

## Step 1: Installation prerequisites

Here, we install required libraries and binaries for Eucalyptus to build
and run. We also update your system and set you as a password-less
sudoer. Add yourself as a password-less 'sudoer' since a lot of the
commands will require super user access and it'll be much easier not to
type your password 72323854542921 times!

    # add yourself as a sudoer
    me=`whoami`
    file=/etc/sudoers.d/$me
    sudo touch $file
    sudo chmod 0440 $file
    sudo sh -c "printf \"%s\\tALL=(ALL)\\tNOPASSWD: ALL\\n\" $me >$file"
    sudo chmod 0440 $file

Upgrade your Ubuntu box with the latest packages & kernel. You will need
to restart if this step ends up installing a new kernel version.

    # update your system
    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get dist-upgrade

Install some (some not) useful applications, including the build &
runtime dependencies for Eucalyptus.

    # install some useful applications
    sudo apt-get -y install ssh subversion git vim rsync wget

    # install eucalyptus build dependencies
    # WARNING: install these now, not later
    sudo apt-get -y install cdbs debhelper libaxis2c-dev librampart-dev \
      libvirt-dev libfuse-dev libfuse2 libcurl4-openssl-dev \
      libssl-dev ant-optional zlib1g-dev pkg-config swig python \
      python-setuptools open-iscsi libxslt1-dev gengetopt ant \
      postgresql-server-dev-9.1 openjdk-7-jdk groovy libcap-dev

    # install eucalyptus runtime dependencies
    # WARNING: install these now, not later
    sudo apt-get install -y bridge-utils iputils-arping libapache2-mod-axis2c adduser \
      apache2 apache2-mpm-worker bridge-utils dhcp3-server euca2ools file \
      iptables iputils-arping libapache2-mod-axis2c libaxis2c0 libc6 \
      libcrypt-openssl-random-perl libcrypt-openssl-rsa-perl libcrypt-x509-perl \
      libcurl3 libdevmapper1.02.1 libpam-modules librampart0 libssl1.0.0 libvirt0 \
      libvirt-bin libxml2 libxslt1.1 lvm2 open-iscsi openssh-client openssh-server \
      parted postgresql-client-9.1 python python2.7 python-boto python-psutil \
      rsync sudo tgt vblade vlan vtun postgresql-9.1 apache2-threaded-dev \
      bzr drbd8-utils gcc kvm libsys-virt-perl libxml-simple-perl make openntpd \
      python-libvirt python-pygresql qemu-kvm unzip at

    # install axis2
    wget http://archive.apache.org/dist/ws/axis2/1_4/axis2-1.4-bin.zip
    sudo unzip axis2-1.4-bin.zip -d /opt

We have to disable apparmor on Ubuntu, so as to avoid conflicts with
Eucalyptus. 

**WARNING:** Removing apparmor could lower your system's
security, but it has to be done since it conflicts with Eucalyptus in a
few ways. A workaround would require tuning the `/etc/apparmor.d/`
configuration files.

    # we must disable apparmor to avoid DHCP/libvirt daemon issues
    sudo service apparmor stop
    sudo service apparmor teardown
    sudo apt-get remove apparmor

    # restart libvirt-bin after removing apparmor
    sudo service libvirt-bin restart

Eucalyptus needs an ethernet bridge device on which instance network
adapters can attach to. This way, your box will be able to talk to an
instance and viceversa. 

**WARNING:** I am using 10.1.0.1 as the bridge's
IP address here. Please make sure it does not conflict with your
existing network configuration, or change it otherwise.

    # add a br0 bridge interface to your /etc/network/interfaces file
    # WARNING: no need to attach your eth0 or any other card to this bridge
    sudo sh -c 'echo "\nauto br0\niface br0 inet static\naddress 10.1.0.1\nnetmask 255.255.0.0\nbridge_stp off\nbridge_ports none" >>/etc/network/interfaces'

    # bring the bridge up
    sudo ifup br0

    # make sure the bridge is up
    sudo brctl show br0
    ifconfig br0

**NOTE:** Please restart your system if a new kernel was installed in the
upgrade/dist-upgrade process.

    sudo reboot now

## Step 2: Download Eucalyptus 3.3.0.1 from GitHub

    # download eucalyptus 3.3.0.1 from github
    git clone https://github.com/eucalyptus/eucalyptus.git
    pushd eucalyptus/
    git checkout 3.3.0.1
    popd

## Step 3: Configure Eucalyptus for building

    # configure eucalyptus
    export JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64"
    export JAVA="$JAVA_HOME/jre/bin/java"
    export EUCALYPTUS="/"

    pushd eucalyptus/
    ./configure \
      --prefix=$EUCALYPTUS \
      --with-axis2c=/usr/lib/axis2 \
      --with-axis2c-services=/usr/lib/axis2/services \
      --with-apache2-module-dir=/usr/lib/apache2/modules \
      --with-axis2=/opt/axis2-1.4
    popd

## Step 4: Patch a few build issues

### Fix Axis-related linking errors in storage/Makefile

You can download the patch file here:
[storage-makefile.patch](/files/storage-makefile.patch)

    wget --user-agent=Mozilla http://alinush.github.io/files/storage-makefile.patch
    mv storage-makefile.patch eucalyptus/
    pushd eucalyptus/
    patch -p1 < storage-makefile.patch
    popd

### Fix Groovy-related errors in clc/Makefile

You can download the patch file here:
[clc-makefile.patch](/files/clc-makefile.patch)

    wget --user-agent=Mozilla http://alinush.github.io/files/clc-makefile.patch
    mv clc-makefile.patch eucalyptus/
    pushd eucalyptus/
    patch -p1 < clc-makefile.patch
    popd

## Step 5: Build Eucalyptus

    # build eucalyptus with make
    export JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64"
    export JAVA="$JAVA_HOME/jre/bin/java"
    export EUCALYPTUS="/"

    pushd eucalyptus/
    make
    popd

## Step 6: Pre-installation requirements

There are a few things we must do, before we can install Eucalyptus with
`sudo make install`.

    # pre-installation requirements (add eucalyptus user/group)
    sudo addgroup eucalyptus
    sudo adduser eucalyptus --ingroup eucalyptus
    sudo usermod -d /var/lib/eucalyptus/ eucalyptus
    sudo ln -s /lib/udev/scsi_id /usr/bin/scsi_id

## Step 7: Install Eucalyptus

    export JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64"
    export JAVA="$JAVA_HOME/jre/bin/java"
    export EUCALYPTUS="/"

    # install eucalyptus with make
    pushd eucalyptus/
    sudo make install
    popd

## Step 8: Post-installation requirements

    # post-installation requirements (set permissions, copy XML fault files)
    sudo chown -R eucalyptus:eucalyptus /etc/eucalyptus /var/lib/eucalyptus/ /var/log/eucalyptus
    sudo chmod +s /usr/lib/eucalyptus/euca_rootwrap -v

    sudo adduser `id -un` libvirtd
    sudo adduser eucalyptus libvirtd
    sudo adduser `id -un` kvm
    sudo adduser eucalyptus kvm

    sudo mkdir -p /var/lock/subsys
    sudo mkdir -p /var/run/eucalyptus
    sudo chown -R eucalyptus:eucalyptus /var/lock/subsys /var/run/eucalyptus

    sudo mkdir -p /etc/eucalyptus/faults/en_US
    sudo cp eucalyptus/util/faults/en_US/* /etc/eucalyptus/faults/en_US/

## Step 9: Configure Eucalyptus by editing /etc/eucalyptus/eucalyptus.conf

You should start off with this `eucalyptus.conf` file from
[here](/files/eucalyptus-3.3.conf)
and edit it to match your network configuration.

    wget --user-agent=Mozilla http://alinush.github.io/files/eucalyptus-3.3.conf
    sudo mv /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig
    sudo cp eucalyptus-3.3.conf /etc/eucalyptus

    # edit /etc/eucalyptus/eucalyptus.conf in your favorite editor 
    vim /etc/eucalyptus/eucalyptus.conf

    # the settings you might need to change are:
    VNET_PUBLICIPS="10.0.0.100-10.0.0.253"
    VNET_DNS="10.0.0.1"

    VNET_SUBNET="10.1.0.0"
    VNET_NETMASK="255.255.255.0"
    VNET_ADDRSPERNET="32"

**WARNING:** Here i am assuming you are behind a NAT router (your typical
WiFi router with DNS and DHCP), whose address is 10.0.0.1. If that's not
the case, please change the `VNET_PUBLICIPS` and the `VNET_DNS` to match
your router's configuration. Ideally, you would also have your router
configured to ONLY assign addresses below 10.0.0.100 since we are
reserving the rest for Eucalyptus instances. However, as long as you
have less than 100 physical machines on your network this should not
pose a problem. 

**WARNING:** Also know that the Eucalypus virtual network
(`VNET_SUBNET`) is in the 10.1.0.0/24 subnet, so you will need to change
that as well in `eucalyptus.conf` if it conflicts with your network.

## Step 10: Initialize the Cloud Controller (CLC)

Now, we are ready to initialize the CLC.

    # some pre-initialization setup
    sudo service postgresql restart
    sudo killall dnsmasq

    sudo mkdir -p /var/lock/subsys
    sudo mkdir -p /var/run/eucalyptus
    sudo chown -R eucalyptus:eucalyptus /var/lock/subsys /var/run/eucalyptus

    # initialize the Cloud Controller (CLC)
    sudo /usr/sbin/euca_conf --setup
    # check the logs while this is being executed (see below)
    sudo /usr/sbin/euca_conf --initialize

    # mark the logs as readable and writable by everyone
    sudo chmod -R a+rw /var/log/eucalyptus/

While the `euca_conf --initialize` command is running, you should check
the CLC logs to see what's happening.

    # WARNING: 'euca_conf --initialize' can either loop infinitely if something is wrong
    # or return with an error.
    # To be sure, you can tail -f cloud-output.log to see what's going on
    tail -f /var/log/eucalyptus/cloud-output.log

The last logs before a sucessful `euca_conf --initialize` on my machine
were:

    2013-06-18 15:41:02 INFO | -> Setup done for persistence context: eucalyptus_cloud
    2013-06-18 15:41:02 INFO | Trying to load config for com.eucalyptus.util.StorageProperties from //etc/eucalyptus/cloud.d/scripts/storageprops.groovy
    2013-06-18 15:41:05 INFO | -> Setup done for persistence context: eucalyptus_storage
    2013-06-18 15:41:08 INFO | -> Setup done for persistence context: eucalyptus_autoscaling
    2013-06-18 15:41:09 INFO | -> Setup done for persistence context: eucalyptus_records
    2013-06-18 15:41:17 INFO | -> Setup done for persistence context: eucalyptus_cloudwatch
    2013-06-18 15:41:17 INFO | -> Setup done for persistence context: eucalyptus_general
    2013-06-18 15:41:21 INFO | -> Setup done for persistence context: eucalyptus_auth
    2013-06-18 15:41:22 INFO | -> Setup done for persistence context: eucalyptus_config
    2013-06-18 15:41:24 INFO | -> Setup done for persistence context: eucalyptus_loadbalancing
    2013-06-18 15:41:27 INFO | -> Setup done for persistence context: eucalyptus_walrus
    2013-06-18 15:41:28 INFO | -> Setup done for persistence context: eucalyptus_dns
    2013-06-18 15:41:29 INFO | -> Setup done for persistence context: eucalyptus_faults
    2013-06-18 15:41:31 INFO | -> Setup done for persistence context: eucalyptus_reporting
    2013-06-18 15:41:31 INFO | :1371584491778:Bootstrap:bootstrap:COMPONENT_REGISTERED:Component eucalyptus=available service=not-local
    | :1371584491778:Bootstrap::bootstrap:COMPONENT_REGISTERED:
    2013-06-18 15:41:31 INFO | :1371584491780:ServiceConfigurations:bootstrap:COMPONENT_REGISTERED:ServiceConfiguration eucalyptus arn:euca:eucalyptus:192.168.1.102/ 192.168.1.102:8773:/services/Eucalyptus:vm-local:host-local:PRIMORDIAL
    2013-06-18 15:41:31 INFO | Added registration for this cloud controller: ServiceConfiguration eucalyptus arn:euca:eucalyptus:::192.168.1.102/ 192.168.1.102:8773:/services/Eucalyptus:vm-local:host-local:PRIMORDIAL
    2013-06-18 15:41:31 INFO | Postgres command : '/usr/lib/postgresql/9.1/bin/pg_ctl' 'status' '-D//var/lib/eucalyptus/db/data'
    2013-06-18 15:41:31 INFO | stdout: pg_ctl: server is running (PID: 17976)
    2013-06-18 15:41:31 INFO | stdout: /usr/lib/postgresql/9.1/bin/postgres "-D" "/var/lib/eucalyptus/db/data" "-h0.0.0.0/0" "-p8777" "-i"
    2013-06-18 15:41:31 INFO | Postgres command : '/usr/lib/postgresql/9.1/bin/pg_ctl' 'stop' '-mf' '-D//var/lib/eucalyptus/db/data'
    2013-06-18 15:41:38 INFO | stdout: waiting for server to shut down.......... done
    2013-06-18 15:41:38 INFO | stdout: server stopped
    2013-06-18 15:41:38 INFO | Executing Pre-Shutdown Hooks...
    2013-06-18 15:41:38 INFO | Executing Shutdown Hooks...
    2013-06-18 15:41:38 INFO | Executing Shutdown Hook: com.eucalyptus.component.BasicService$1@180d47cf
    2013-06-18 15:41:38 WARN | Parsing common file /usr/share/eucalyptus/faults/en_US/common.xml
    2013-06-18 15:41:39 WARN | Parsing common file /etc/eucalyptus/faults/en_US/common.xml
    2013-06-18 15:41:39 WARN | SHUTDOWN Service: arn:euca:eucalyptus::db:192.168.1.102/
    2013-06-18 15:41:39 INFO | Executing Post-Shutdown Hooks...
    2013-06-18 15:41:39 INFO | Executing Post-Shutdown Hook: com.eucalyptus.system.Threads$ThreadPool$1@2bb3e57c
    2013-06-18 15:41:39 WARN | SHUTDOWN:Eucalyptus.SYSTEM Stopping thread pool...
    2013-06-18 15:41:39 INFO | Executing Post-Shutdown Hook: PostgresqlBootstrapper$3@2f9f464e
    2013-06-18 15:41:39 INFO | Executing Post-Shutdown Hook: com.eucalyptus.system.Threads$ThreadPool$1@3cf6fa16
    2013-06-18 15:41:39 WARN | SHUTDOWN:Eucalyptus.bootstrap:Futures Stopping thread pool...

## Step 11: Start the Eucalyptust cloud services

Now, let's start the Cloud Controller (CLC), Walrus, Cluster Controller
(CC), Storage Controller (SC) and Node Controller (NC).

    # openntpd needs to be started for time synchronization
    sudo service openntpd restart

    # if JDBC cannot write to a temp file in /tmp, then eucalyptus CLC will fail
    sudo chmod 0777 /tmp

    # for the 3rd time, these directories have to exist!
    sudo mkdir -p /var/lock/subsys /var/run/eucalyptus
    sudo chown -R eucalyptus:eucalyptus /var/lock/subsys /var/run/eucalyptus

    # start the eucalyptus services
    sudo service eucalyptus-cloud start
    sudo service eucalyptus-cc start
    sudo service eucalyptus-nc start

**NOTE:** You might get a message when starting the NC, complaining about
the keys not being found. That's okay, just ignore it for now.

    Cannot find keys (node-pk.pem, node-cert.pem) in //var/lib/eucalyptus/keys

As always, please check the CLC logs while services are starting. You
will not be able to check the CC and NC logs until later when we
register them with the CLC.

    # To be sure all is well, you can tail -f cloud-output.log to see what's going on
    tail -f /var/log/eucalyptus/cloud-output.log

The last CLC logs will look like this. Notice that the Elastic Load
Balancer (ELB) needs to be set up.

    2013-07-06 15:36:33 INFO | Postgres command : '/usr/lib/postgresql/9.1/bin/pg_ctl' 'status' '-D//var/lib/eucalyptus/db/data'
    2013-07-06 15:36:33 INFO | stdout: pg_ctl: server is running (PID: 1154)
    2013-07-06 15:36:33 INFO | stdout: /usr/lib/postgresql/9.1/bin/postgres "-D" "/var/lib/eucalyptus/db/data" "-h0.0.0.0/0" "-p8777" "-i"
    2013-07-06 15:36:35 ERROR | START:DISABLED arn:euca:eucalyptus::loadbalancing:10.0.0.3/ NOTREADY->DISABLED=NOTREADY [LoadBalancingPropertyBootstrapper.enable( ): returned false, terminating bootstrap for component: loadbalancing]
    2013-07-06 15:36:35 ERROR | START:DISABLED arn:euca:eucalyptus::loadbalancing:10.0.0.3/ NOTREADY->DISABLED=NOTREADY [LoadBalancingPropertyBootstrapper.enable( ): returned false, terminating bootstrap for component: loadbalancing]
    2013-07-06 15:36:35 ERROR | START:DISABLED arn:euca:eucalyptus::loadbalancing:10.0.0.3/ NOTREADY->DISABLED=NOTREADY [LoadBalancingPropertyBootstrapper.enable( ): returned false, terminating bootstrap for component: loadbalancing]
    2013-07-06 15:36:36 ERROR | START:DISABLED arn:euca:eucalyptus::loadbalancing:10.0.0.3/ NOTREADY->DISABLED=NOTREADY [LoadBalancingPropertyBootstrapper.enable( ): returned false, terminating bootstrap for component: loadbalancing]
    2013-07-06 15:36:36 ERROR | START:DISABLED arn:euca:eucalyptus::loadbalancing:10.0.0.3/ NOTREADY->DISABLED=NOTREADY [LoadBalancingPropertyBootstrapper.enable( ): returned false, terminating bootstrap for component: loadbalancing]
    2013-07-06 15:36:37 ERROR | START:DISABLED arn:euca:eucalyptus::loadbalancing:10.0.0.3/ NOTREADY->DISABLED=NOTREADY [LoadBalancingPropertyBootstrapper.enable( ): returned false, terminating bootstrap for component: loadbalancing]
    2013-07-06 15:36:39 INFO | Hosts.entrySet(): 10.0.0.3 finished.
    2013-07-06 15:36:39 INFO | Hosts.entrySet(): 10.0.0.3 finished.'

## Step 12: Register the Eucalyptus components

We have to register the CC, SC and Walrus with the CLC. And we also have
to register the NC with the CC. 

**WARNING:** Once again, this step
assumes that you are behind a router whose address is 10.0.0.1. Adjust as
necessary.

    # set a root password on your machine, you will be asked for it later
    sudo passwd

    # generate an SSH key for root, and let root@localhost ssh into root@localhost
    # (this is for convenience, so that you do not get prompted for the root
    # password when you register the components later on)
    if sudo su -c "test ! -f /root/.ssh/id_rsa"; then
        sudo su -c 'ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ""'
    fi

    # here you will be prompted for the password you entered above in 'sudo passwd'
    sudo su -c "ssh-copy-id root@localhost"

    # WARNING: the assumption here is that you are behind a NAT'ed network (you are using a router)
    # and your NAT-assigned IP address is 10.0.0.100. also, the IP address on the br0 bridge should be 10.1.0.1
    cluster=cluster01
    extaddr=10.0.0.100
    intaddr=10.1.0.1

    # register the components
    sudo -u root /usr/sbin/euca_conf --register-walrus --partition walrus --host $extaddr --component walrus-$extaddr
    sudo -u root /usr/sbin/euca_conf --register-cluster --partition $cluster --host $extaddr --component cc-$extaddr
    sudo -u root /usr/sbin/euca_conf --register-sc --partition $cluster --host $extaddr --component sc-$extaddr
    sudo -u root /usr/sbin/euca_conf --register-nodes "$intaddr"

You will get an warning upon registering the SC, which we will deal with
later. Now we can check that everything has registered (it might take a
few seconds for everything to be in the `ENABLED` state).

    # check to be sure everything is registered
    sudo euca_conf --list-clouds
    sudo euca_conf --list-walrus
    sudo euca_conf --list-clusters

    # the --list-sc command will tell you your SC is NOTREADY, BROKEN or DISABLED.
    # we will fix this later.
    sudo euca_conf --list-sc

    # the --list-nodes will not work until you have the eucalyptus 
    # credentials sourced in your environment. so
    # you can check the NC logs to make sure the NC is up
    euca_conf --list-nodes 

    tail -f /var/log/eucalyptus/nc.log

You should see messages like these popping up continuously in the NC
logs:

    2013-07-06 15:45:08 DEBUG 000003546 statfs_path | path '/var/lib/eucalyptus/instances/work' resolved
    2013-07-06 15:45:08 DEBUG 000003546 statfs_path | to '/var/lib/eucalyptus/instances/work' with ID 0
    2013-07-06 15:45:08 DEBUG 000003546 statfs_path | of size 99544817664 bytes with available 87483858944 bytes
    2013-07-06 15:45:08 DEBUG 000003546 statfs_path | path '/var/lib/eucalyptus/instances/cache' resolved
    2013-07-06 15:45:08 DEBUG 000003546 statfs_path | to '/var/lib/eucalyptus/instances/cache' with ID 0
    2013-07-06 15:45:08 DEBUG 000003546 statfs_path | of size 99544817664 bytes with available 87483858944 bytes
    2013-07-06 15:45:12 DEBUG 000000786 doDescribeResource | returning status=enabled cores=2/2 mem=7813/7813 disk=25/25 iqn=iqn.1993-08.org.debian:01:4eccde31f9c
    2013-07-06 15:45:12 DEBUG 000000786 doDescribeInstances | invoked userId=eucalyptus correlationId=UNSET epoch=31 services[0]{.name=cc-10.0.0.3 .type=cluster .uris[0]=http://10.0.0.3:8774/axis2/services/EucalyptusCC}
    2013-07-06 15:45:18 DEBUG 000000786 doDescribeResource | returning status=enabled cores=2/2 mem=7813/7813 disk=25/25 iqn=iqn.1993-08.org.debian:01:4eccde31f9c
    2013-07-06 15:45:18 DEBUG 000000786 doDescribeInstances | invoked userId=eucalyptus correlationId=UNSET epoch=31 services[0]{.name=cc-10.0.0.3 .type=cluster .uris[0]=http://10.0.0.3:8774/axis2/services/EucalyptusCC}
    2013-07-06 15:45:25 DEBUG 000000786 doDescribeResource | returning status=enabled cores=2/2 mem=7813/7813 disk=25/25 iqn=iqn.1993-08.org.debian:01:4eccde31f9c
    2013-07-06 15:45:25 DEBUG 000000786 doDescribeInstances | invoked userId=eucalyptus correlationId=UNSET epoch=31 services[0]{.name=cc-10.0.0.3 .type=cluster .uris[0]=http://10.0.0.3:8774/axis2/services/EucalyptusCC}
    2013-07-06 15:45:31 DEBUG 000000786 doDescribeResource | returning status=enabled cores=2/2 mem=7813/7813 disk=25/25 iqn=iqn.1993-08.org.debian:01:4eccde31f9c'

## Step 13: Retrieve and 'source' your Eucalyptus admin user credentials

To give commands to the cloud, you will need to 'download' the admin
credentials from Eucalyptus and source them in your environment.

    # get your eucalyptus admin user credentials and source them in your current terminal/environment
    userid=`id -u`
    mkdir -p credentials/
    sudo /usr/sbin/euca_conf --get-credentials admin.zip
    sudo chown -R $userid:$userid *
    unzip admin.zip -d credentials/

    . credentials/eucarc

You will see a warning upon sourcing the credentials:
`"WARN: Load Balancing service URL is not configured."` We will fix this
later. 

**WARNING:** From this point on, we assume your eucalyptus
credentials are sourced in your environment. If they are not, please
repeat this step. Now that the credentials are sourced, you will be able
to `--list-nodes` in `euca_conf.`

    euca_conf --list-nodes

## Step 14: Fix the Storage Controller (SC) by setting it into 'overlay' mode

We have to set the Storage Controller (SC) into 'overlay' mode in order
to get it in the `ENABLED` state. Right now it should be in the
`NOTREADY` or `DISABLED` state. First we have to rename the tgt service
to tgtd (seems like this is still an issue with Eucalyptus 3.3 in
Ubuntu).

    sudo service tgt stop
    sudo mv /etc/init/tgt.conf /etc/init/tgtd.conf
    sudo mv /etc/init.d/tgt /etc/init.d/tgtd
    sudo service tgtd start

Now, we can configure the SC to be in 'overlay' mode.

    sc=`euca-describe-properties | grep blockstoragemanager | cut -f 2`
    echo $sc # should print 'cluster01.storage.blockstoragemanager'
    euca-modify-property -p $sc=overlay # should print 'PROPERTY cluster01.storage.blockstoragemanager overlay was '

You can now check that the SC is enabled, but it will take a few seconds
for it to appear as `ENABLED`.

    sudo euca_conf --list-sc

## Step 15: Prepare to launch an instance

Check to see how many instances you can launch. This will depend on the
number of cores on your CPU, on your RAM and on your free hard disk
space.

    # check the cloud's availability, the services
    euca-describe-availability-zones verbose

You should see a few available m1.small instances:

    AVAILABILITYZONE |- m1.small 0002 / 0002 1 256 5

Next, check the status of all services. The ELB service will be in the
`NOTREADY` state. As a result, the output will be huge sometimes, so
just reissue the command a few times.

    euca-describe-services

You will see a line like this for the load balancer service:

    SERVICE loadbalancing eucalyptus 10.0.0.3 NOTREADY 32 http://10.0.0.3:8773/services/LoadBalancing arn:euca:eucalyptus::loadbalancing:10.0.0.3/

We must enable IP forwarding, to allow Eucalyptus to do some routing.

    sudo su -c 'echo 1 >/proc/sys/net/ipv4/ip_forward'

Next, we have to generate an RSA keypair for SSH and store the public
key part in the cloud, keeping the private key to ourselves.

    # generate an SSH keypair in Eucalyptus (use euca-create-keypair if euca-add-keypair does not work)
    euca-add-keypair mykey | grep -v ^KEYPAIR >mykey.pem

`mykey.pem` should look something like this: **WARNING: To prevent you
from using this key, I have changed the output considerably, please
generate your own using this command, as opposed to being lazy and just
copy & pasting, which will create serious security issues.**

    -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEAzXvt+fgXobj70WwbNFsSuLA0kou6h8WCOy+66JQR+2Ri9UCK
    4kC64bWMZhnKoGJtJxBsW7bSSj+P7VxVUQlFiBxyeX5OKatW6C36ZBoQHWG9OvSG
    I/jJCSoHf3+2q2x1encm+MP2WMiMBz5f+X3z2Ruf+HRetovn4ZC8RPliaDf9gpfK
    AAdUCGqIH/Hxn9nGtRaUgzLwORudE+KV7KSeOCioYwhItb2I/AMH0PA9lufKT2fi
    Z2ncm+MP2WMiMBz5f+X3zaDVlPkJp/44r0wjjk7gVgOAkGA+dklGTsrV4Xp3Yi3r
    VxrMZpKMUa1GUNTSQWHNu7jDeIxbbSePyOhJiQIDAQABAoIBADrHd6SotkHZw5b9
    gK6yWqGgLfm5pKsP8ZfyqFm9eYNbDP+w7cmY0JyeLUJLoG3OmgCxrv1xR6hblFVG
    s1UR/OTZlllwqvU6gQq7lEOsPO3ataG1ruV9Viyb7DcpllxlExnsGabRj5eIDp5H
    1nZs9CMnxtPwneNEFBmvKFvmpqK+1aK2SK5h0XLnkpVBToDF0H+JyrwPRcXhyoV/
    odTLZnK17AJ7TXLW9uwQsz+PELtAhIMvdlUGaKMPdvXYfsvjIQN26TI3D5DFc4wz
    vlHn5lE+tx+PXzGtsb6fHg/GTB6VOj3wEoAroI1MSrOqWRGxZZzScqW8gn6pPn1E
    h7FN+60CgP+w7cmY0JyeLUJLoG3OmgCxrv1xR6hblFVGabvaOTBrFUjnO+evZxj6
    PyOVyp17LeX8EtDqkS76qDrLPRFdGX+fBs0VexVzqoP9sH/UKZGIjWDdE/5EzS61
    sW4s5R7AHg3it6otX+kulfRwxL+rkponuBRmF9W+MtUY0FzNe+iK4/sCgYEA0IRh
    eG9EOTAH8Bn4peCRyYeQqHoYZXhxGjrYV25bmiOXlIqmmIatHXptYo8YXRmSwRkV
    gD5IOAKs++uShLs+jU9vUDvMrmvKcYlmuS/XRlvp7zcWe1Mt4kddd1agoTpw/zb0
    BDyHaVPKoUtkrkqyFRRHkv4JozUoxvaxYL7fTUsCgYEA0nfhkLYaIx4QVi0ICqWG
    32OBdF0xTOXaVtldIWE3tWZBJEVCnOzFum9hxMxlvAEnsDsDt2ROUpPag3Q9C8zs
    +cOXrDxVZ2j++YVr59I27lxllQyJMfVKOGEGq5BgD7Ld9wTPHjlYWFq6yipuZbye
    boD2O+Ri7d3C+fKyrDFxzokCgYEAnYflu38UI8BNvu9gErGecoqglyfm1oIvsIlU
    eHk/aywIkIhE3tWZBJEVCnOzFum9hxs2IyrqlKYw2gIXJ3/uugORLSSAdiWpRC1y
    FeY21UkLa1ZK/dDRkWopCse/gw8L30Q9BhZUlxZet4yl+6ci8xnnGP4jedHnhKlL
    SLPrMBECgYArt3WY7TpAtYpWxPu3pO58G6bSLRU6MuUanoNUZUbVBYpbgBL0xnWv
    srEq6rq7iKNQHlEKeJ8U50ikpeiuWvjLZ/YjV2f8H2uV+15zuZePGOEFt1nurHkV
    RG/LbNYa1/L0ieWCKMsCf/u6C9tgZmYfFeNKP04tWGRXYhsBDhc/6g==
    -----END RSA PRIVATE KEY-----

Once you have the file with the key make sure to change permissions so
only you can read and write the file.

    chmod 0600 mykey.pem

## Step 16: Install the newer euca2ools 3.0 from GitHub sources

We must update euca2ools to the latest 3.0 version, since there seems to
be a bug in `eustore-install-image` that does not allow the 'eucalyptus'
admin user to install an OS image.

    git clone https://github.com/eucalyptus/euca2ools.git
    pushd euca2ools/
    git checkout 3.0.0
    popd

    sudo apt-get remove euca2ools # WARNING: This is IMPORTANT!

    pushd euca2ools/
    sudo python setup.py install
    popd

## Step 17: Install an OS image from eustore in your cloud

Now we can download and install an OS image that we can run in the cloud
as a VM.

    eustore-describe-images

We want to install an EMI that's KVM-compatible, so I selected this one:

    1424900416 opensuse x86_64 starter OpenSUSE 12.2 x86_64 - KVM image. SUSE Firewall off. Root disk of 2.5G. Root user enabled. Working with kexec kernel and ramdisk. OpenSUSE minimal base package set.

Download & install the OpenSUSE EMI. This took 20 minutes on my machine
to download, on a 4Mbit/s coonection:

    # NOTE: use the --debug flag to see what's going on 
    # (the command does not seem to print any output on my machine otherwise)
    eustore-install-image -i 1424900416 -b osimages --debug
    euca-describe-images

## Step 18: Start an instance (a.k.a. a VM) in your cloud

First, we must load the KVM kernel module.

    # start KVM for Intel
    sudo modprobe kvm_intel
    # ...or start KVM for AMD
    sudo modprobe kvm_amd

Get the first EMI in the list of images (you only have one at this
point).

    emi=`euca-describe-images | grep IMAGE | grep emi-........ -o | head -n 1`

Start an instance! This will take a few minutes to start up, since the
NC has to download the EMI from Walrus.

    euca-run-instances -k mykey -t m1.small $emi

Wait a few minutes until euca-describe-instances marks your instance as
`running`.

    euca-describe-instances

Check out the console output of the instance.

    inst=`euca-describe-instances | grep running | head -n 1 | cut -f 2`
    euca-get-console-output $inst

Get the instance's IP and connect to it.

    inst_ip=`euca-describe-instances | grep running | cut -f 4`

    # remove a previous host key (if any) at that address
    ssh-keygen -R $inst_ip &>/dev/null

    # you need to authorize SSH access in your default security group
    euca-authorize -P tcp -p 22 -s 0.0.0.0/0 default

    # now you can connect to your instance and check if internet
    # connectivity works inside it
    ssh -i mykey.pem root@$inst_ip

You should see the following output:

    The authenticity of host '10.0.0.100 (10.0.0.100)' can't be established.
    ECDSA key fingerprint is 57:76:26:5d:2e:82:98:0b:e8:9e:1e:2b:d3:6c:9f:7b.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added '10.0.0.100' (ECDSA) to the list of known hosts.

    Last login: Sat Jul 6 18:15:21 2013 from 10.1.0.97
    Have lots of Eucalyptus fun...
    ip-10-1-0-122:~ # # you can ping/wget google.com inside the instance
    ip-10-1-0-122:~ # wget google.com
    ip-10-1-0-122:~ # ping google.com

    PING google.com (74.125.226.238) 56(84) bytes of data.

    64 bytes from lga15s29-in-f14.1e100.net (74.125.226.238): icmp_seq=1 ttl=53 time=586 ms
    64 bytes from lga15s29-in-f14.1e100.net (74.125.226.238): icmp_seq=2 ttl=53 time=607 ms
    64 bytes from lga15s29-in-f14.1e100.net (74.125.226.238): icmp_seq=3 ttl=53 time=558 ms
    64 bytes from lga15s29-in-f14.1e100.net (74.125.226.238): icmp_seq=4 ttl=53 time=507 ms
    64 bytes from lga15s29-in-f14.1e100.net (74.125.226.238): icmp_seq=5 ttl=53 time=438 ms
    64 bytes from lga15s29-in-f14.1e100.net (74.125.226.238): icmp_seq=6 ttl=53 time=472 ms
    64 bytes from lga15s29-in-f14.1e100.net (74.125.226.238): icmp_seq=7 ttl=53 time=656 ms
    ^C
    --- google.com ping statistics ---
    7 packets transmitted, 7 received, 0% packet loss, time 11108ms
    rtt min/avg/max/mdev = 438.535/546.710/656.002/71.824 ms"

## Step 19: Attach a volume to your instance

Now we can play with EBS volumes.

    euca-create-volume -z cluster01 -s 5
    euca-describe-volumes

Once the volume becomes available, try attaching it to the instance.

    vol=`euca-describe-volumes | grep available | head -n 1 | cut -f 2`
    euca-attach-volume -i $inst -d /dev/vdb $vol

Check to see if the volume attached.

    euca-describe-volumes

The output of `euca-describe-volumes` should look like this:

    VOLUME vol-1E573DBC 5 cluster01 in-use 2013-07-06T22:27:04.372Z standard
    ATTACHMENT vol-1E573DBC i-DC213D33 unknown,requested:/dev/vdb attaching 2013-07-06T22:31:55.979Z

Inside the instance, you can check `dmesg` logs to see if the volume
attached.

    ip-10-1-0-122:~ # dmesg

The output should look like this (note the `/dev/vdb` device created at
the end):

    [ 1114.557787] pci 0000:00:06.0: [1af4:1001] type 00 class 0x010000
    [ 1114.557970] pci 0000:00:06.0: reg 10: [io 0x0000-0x003f]
    [ 1114.558062] pci 0000:00:06.0: reg 14: [mem 0x00000000-0x00000fff]
    [ 1114.559107] pci 0000:00:06.0: BAR 1: assigned [mem 0x80000000-0x80000fff]
    [ 1114.559158] pci 0000:00:06.0: BAR 0: assigned [io 0x1000-0x103f]
    [ 1114.559210] pci 0000:00:00.0: no hotplug settings from platform
    [ 1114.559211] pci 0000:00:00.0: using default PCI settings
    [ 1114.559268] pci 0000:00:01.0: no hotplug settings from platform
    [ 1114.559287] pci 0000:00:01.0: using default PCI settings
    [ 1114.559356] ata_piix 0000:00:01.1: no hotplug settings from platform
    [ 1114.559358] ata_piix 0000:00:01.1: using default PCI settings
    [ 1114.559414] uhci_hcd 0000:00:01.2: no hotplug settings from platform
    [ 1114.559416] uhci_hcd 0000:00:01.2: using default PCI settings
    [ 1114.559483] piix4_smbus 0000:00:01.3: no hotplug settings from platform
    [ 1114.559485] piix4_smbus 0000:00:01.3: using default PCI settings
    [ 1114.559540] virtio-pci 0000:00:03.0: no hotplug settings from platform
    [ 1114.559542] virtio-pci 0000:00:03.0: using default PCI settings
    [ 1114.559596] virtio-pci 0000:00:04.0: no hotplug settings from platform
    [ 1114.559598] virtio-pci 0000:00:04.0: using default PCI settings
    [ 1114.559652] virtio-pci 0000:00:05.0: no hotplug settings from platform
    [ 1114.559654] virtio-pci 0000:00:05.0: using default PCI settings
    [ 1114.559708] pci 0000:00:06.0: no hotplug settings from platform
    [ 1114.559709] pci 0000:00:06.0: using default PCI settings
    [ 1114.569109] virtio-pci 0000:00:06.0: enabling device (0000 -> 0003)
    [ 1114.571647] ACPI: PCI Interrupt Link [LNKB] enabled at IRQ 11
    [ 1114.579644] virtio-pci 0000:00:06.0: setting latency timer to 64
    [ 1114.580116] virtio-pci 0000:00:06.0: irq 45 for MSI/MSI-X
    [ 1114.580148] virtio-pci 0000:00:06.0: irq 46 for MSI/MSI-X
    [ 1114.584510] vdb: unknown partition table

Feel free to write some data on your volume.

    ip-10-1-0-122:~ # sudo mkfs.ext2 /dev/vdb
    ip-10-1-0-122:~ # sudo mount /dev/vdb /mnt
    ip-10-1-0-122:~ # echo hello >/mnt/hello
    ip-10-1-0-122:~ # sudo umount /dev/vdb

Now you can safely detach the volume.

    euca-detach-volume $vol

Feel free to reattach the volume and check that the data is still there.

## Step 20: Terminate your instance


Terminate the instance using `euca-terminate-instances`

    euca-terminate-instances $inst

## Bonus Step: Get the Elastic Load Balancer to work

I have not used the Elastic Load Balancer at all, but I can show you how
to enable it and hopefully you can figure out the rest. First, we have
to download an elastic load balancer EMI. We use one provided as an
`rpm` by Eucalyptus on their website.

    wget http://downloads.eucalyptus.com/software/eucalyptus/3.3/centos/6/x86_64/eucalyptus-load-balancer-image-1.0.0-0.92.el6.x86_64.rpm

    sudo apt-get install rpm

    sudo rpm -i --nodeps eucalyptus-load-balancer-image-1.0.0-0.92.el6.x86_64.rpm

Next, we must install the ELB EMI.

    git clone https://github.com/eucalyptus/load-balancer-image.git

    pushd load-balancer-image/
    ./euca-install-load-balancer --install-default
    popd

Your output should be similar to this:

    Preparing to extract image...
    -- Uploading ramdisk image --
    Registered ramdisk image eri-85E93353
    -- Uploading kernel image --
    Registered kernel image eki-42933821
    -- Uploading machine image --
    Registered machine image emi-870E3685
    -- Done --
    PROPERTY loadbalancing.loadbalancer_emi emi-870E3685 was NULL

    Load Balancer Support is Enabled

Now, we should check to see the ELB service is working.

    euca-describe-services | grep loadbalancing

Hopefully, you see the same message.

    SERVICE loadbalancing eucalyptus 10.0.0.3 ENABLED 31 http://10.0.0.3:8773/services/LoadBalancing arn:euca:eucalyptus::loadbalancing:10.0.0.3/

That's all!
-----------

Enjoy your cloud!

 > This page used to be at `http://alinush.org/2013/07/21/how-to-compile-and-install-eucalyptus-3-3-0-on-ubuntu-13-04-from-github-sources-cloud-in-a-box/`
