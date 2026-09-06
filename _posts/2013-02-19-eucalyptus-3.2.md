---
tags: tutorials
date: 2013-02-19 13:30:00
title: How to compile and install Eucalyptus 3.2.0 on Ubuntu 12.04/12.10 from Github sources (cloud-in-a-box)
permalink: eucalyptus-3.2
---

Recently, I've been spending my time up in the clouds (i.e. _sunt cu capul in nori_) messing around with Eucalyptus.
Eucalyptus is an open-source cloud platform. 
In my experience, this means that you can download it from GitHub, compile it and then torture yourself trying to get it to run :)
Here, I am presenting a short guide on building, installing and configuring Eucalyptus 3.2.0. 
To maximize pain, feel free to ignore everything I say below.

Prerequisites
-------------

You need...

 - A Linux-capable machine with virtualization extensions
 - Space on your disk to install Ubuntu 12.04
 - More than 30GB of free space in /var/lib/eucalyptus. 
   I had one 67GB root partition with 45GB free. 
   Please note that not having sufficient free space on the Node Controller (NC) machine will prevent you from launching instances with a nasty `"Not enough resources (0 in default 1): vm instances"` message.

WARNINGS
--------

 - These are instructions for a _cloud-in-a-box_ installation (Cloud, Cluster and Node Controller will be installed on one machine)
 - These are instructions for Ubuntu 12.04. Other Linux systems will need different prerequisites most likely, however the Eucalyptus-specific actions should (mostly) remain the same.
 - I am reproducing my steps on Ubuntu 12.04 as I remember them. Some things may be forgotten :(
 - This should (in theory) work on Ubuntu 12.10 as well. 
   The compilation might pose some problems if you have Java 7 installed.
   By getting rid of any trace of OpenJDK 7, and replacing it with OpenJDK 6, I was able to also compile, install and run on 12.10, but I could never launch an instance due to lack of hard-disk space at the time.

Step 0: Install Ubuntu 12.04
----------------------------

Download Ubuntu 12.04 x86\_64 Desktop Edition:
[http://www.ubuntu.com/download/desktop](http://www.ubuntu.com/download/desktop)
Install Ubuntu 12.04 x86\_64 Desktop Edition. 
Boot into your new Ubuntu installation, and set yourself as a password-less sudoer, to save some
time:

    me=`whoami`
    file=/etc/sudoers.d/$me

    sudo touch $file
    sudo chmod 0440 $file
    sudo sh -c "printf \"%s\\tALL=(ALL)\\tNOPASSWD: ALL\\n\" $me >$file"
    sudo chmod 0440 $file

Update your system and reboot.

    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get dist-upgrade
    sudo reboot now

Step 1: Install build prerequisites
-----------------------------------

**NOTE:** I am not sure if Ubuntu 12.0.2 comes with OpenJDK 7, but if you get compilation errors later on, this could be the issue and you might need to remove OpenJDK 7 and install OpenJDK 6.
These are not all necessary, still, I am blindly following what I did.

    sudo apt-get -y install vim subversion git libxss1 \
      build-essential

These are (probably) all necessary.

    sudo apt-get -y install git bzr gcc make \
      apache2-threaded-dev ant openjdk-6-jdk \
      libvirt-dev libcurl4-openssl-dev 
      cdbs debhelper libaxis2c-dev \
      libvirt-dev libfuse-dev libfuse2 libcurl4-openssl-dev \
      libssl-dev ant-optional zlib1g-dev pkg-config swig python \
      python-setuptools rsync wget open-iscsi libxslt1-dev gengetopt \
      librampart-dev ant postgresql-server-dev-9.1

Install Axis2-1.4, this is used in Eucalyptus for SOAP/WSDL, etc.

    wget http://archive.apache.org/dist/ws/axis2/1_4/axis2-1.4-bin.zip
    sudo unzip axis2-1.4-bin.zip -d /opt

Step 2: Download Eucalyptus 3.2.0 from GitHub
---------------------------------------------

To save you some trouble:

    wget https://github.com/eucalyptus/eucalyptus/archive/3.2.0.zip

Step 3: Build Eucalyptus 3.2.0
------------------------------

Extract and build:

    export JAVA_HOME="/usr/lib/jvm/java-6-openjdk-amd64"
    export JAVA="$JAVA_HOME/jre/bin/java"
    export EUCALYPTUS="/"

    unzip 3.2.0.zip

    cd eucalyptus-3.2.0/

    # if you are reconfiguring, then do a 'make distclean' first
    ./configure --with-axis2c=/usr/lib/axis2 \ 
      --prefix=$EUCALYPTUS \
      --with-axis2c-services=/usr/lib/axis2/services \
      --with-apache2-module-dir=/usr/lib/apache2/modules \
      --with-axis2=/opt/axis2-1.4

    # if you are rebuilding, then do a 'make clean' first
    make
    cd -

Step 4: Install runtime prerequisites
-------------------------------------

A lot of them...

    sudo apt-get -y install dhcp3-server \ 
       vblade apache2 unzip curl vlan \
       bridge-utils python-libvirt libvirt-bin kvm vtun

    sudo apt-get -y install adduser apache2 apache2-mpm-worker \
      bridge-utils dhcp3-server drbd8-utils euca2ools file \
      iptables libapache2-mod-axis2c libaxis2c0 libc6 \
      libcrypt-openssl-random-perl libcrypt-openssl-rsa-perl \
      libcrypt-x509-perl libcurl3 libdevmapper libpam-modules \
      librampart0 libssl1.0.0 libvirt0 libvirt-bin libxml2 \
      libxslt1.1 lvm2 open-iscsi openssh-client openssh-server \
      parted postgresql-client-9.1 python python2.7 python-boto \
      python-psutil python-pygresql rsync sudo tgt vblade vlan vtun \
      postgresql openntpd libsys-virt-perl libxml-simple-perl \
      qemu-kvm

Seems like you also need libwsdl2c, which you can get:

    wget http://ftp.br.debian.org/debian/pool/main/w/wsdl2c/libwsdl2c-java_0.1-1_all.deb
    sudo dpkg -i libwsdl2c-java_0.1-1_all.deb

Thanks to Andy Grimm for clarifying that this is not needed, if Axis2-1.4 is used!

Step 5: Setup a network bridge
------------------------------

Since we are doing a cloud-in-a-box installation, Eucalyptus needs a bridge (virtual switch if you'd like) to connect its components so that they can talk to each other. Eucalyptus has various network modes, which you can learn about here: 
[http://www.eucalyptus.com/docs/3.2/ig/configuring\_network\_modes.html](http://www.eucalyptus.com/docs/3.2/ig/configuring_network_modes.html)
Right now, we will set Eucalyptus up in the MANAGED-NOVLAN mode.

    # Backup your current network configuration
    sudo cp /etc/network/interfaces /etc/network/interfaces.orig

    # Write a new configuration in a temporary "interfaces" file
    echo "auto lo
    iface lo inet loopback

    auto br0
    iface br0 inet static
    address 10.1.0.1
    network 10.1.0.0
    netmask 255.255.255.0
    broadcast 10.1.0.255
    gateway 10.1.0.1
    bridge_ports none
    bridge_stp off" >interfaces

    # Overwrite your /etc/network/interfaces file
    sudo cp interfaces /etc/network

    # Bring up the bridge interface
    # (this could take a few seconds)
    sudo ifup br0

Note: I am assuming you don't have a custom `/etc/network/interfaces` file here. 
If you do, just add the `br0` section to your modified `/etc/network/interfaces` file, instead of overwriting as I do above.

Step 6: Install Eucalyptus 3.2.0
--------------------------------

But first, some pre-installation setup:

    # Create the 'eucalyptus' user
    sudo addgroup eucalyptus
    sudo adduser eucalyptus --ingroup eucalyptus
    sudo usermod -d /var/lib/eucalyptus/ eucalyptus

    # Add your user and eucalyptus to libvirtd group...
    sudo adduser `id -un` libvirtd
    sudo adduser eucalyptus libvirtd

    # Add your user to kvm group...
    sudo adduser `id -un` kvm
    sudo adduser eucalyptus kvm

Now, install:

    export JAVA_HOME="/usr/lib/jvm/java-6-openjdk-amd64"
    export JAVA="$JAVA_HOME/jre/bin/java"
    export EUCALYPTUS="/"

    cd eucalyptus-3.2.0/
    sudo make install
    cd -

Now, download my Eucalyptus config file from [here](/files/eucalyptus.conf), and copy it in `/etc/eucalyptus`:

    # Download my eucalyptus configuration to "eucalyptus.conf"
    wget http://alinush.github.io/files/eucalyptus.conf

    # Backup the default eucalyptus.conf file...
    cd /etc/eucalyptus
    sudo cp eucalyptus.conf eucalyptus.conf.orig
    cd -

    # Overwrite the default configuration with mine
    sudo cp eucalyptus.conf /etc/eucalyptus/eucalyptus.conf

Then, some post-installation steps:

    # Create the /var/lock/subsys directory
    sudo mkdir -p /var/lock/subsys
    sudo chown eucalyptus:eucalyptus /var/lock/subsys

    # Copy Eucalyptus faults XML
    mkdir -p /etc/eucalyptus/faults/en_US
    cd eucalyptus-3.2.0
    sudo cp util/faults/en_US/common.xml /etc/eucalyptus/faults/en_US/
    cd -

    # Change Eucalytus directory ownership
    sudo chown -R eucalyptus:eucalyptus /etc/eucalyptus 
    sudo chown -R eucalyptus:eucalyptus /var/lib/eucalyptus/
    sudo chown -R eucalyptus:eucalyptus /var/log/eucalyptus
    sudo chmod +s /usr/lib/eucalyptus/euca_rootwrap

Step 7: Initialize your cloud-in-a-box
--------------------------------------

**WARNING:** This is where you **HAVE to disable your wireless** or wired internet connection.
If you want to be completely safe, turn off networking in Ubuntu's network manager (Right click on Network Manager icon, click on "Enable Networking"). 
If you don't, Eucalyptus will bind to the wrong interface (like wlan0) instead of `br0` and you will have trouble in the next steps. 
Initialize your Eucalyptus cloud:

    # WARNING: Disable your internet connections and all other
    # non-necessary network interfaces
    # Ideally, just lo and br0 should be up and running

    # Eucalyptus needs to start a DNS server, so kill dnsmasq
    sudo killall dnsmasq

    # Create some directories
    sudo mkdir -p /var/lock/subsys
    sudo mkdir -p /var/run/eucalyptus
    sudo chown -R eucalyptus:eucalyptus /var/lock/subsys
    sudo chown -R eucalyptus:eucalyptus /var/run/eucalyptus

    # Sets up ownership and permissions
    sudo /usr/sbin/euca_conf --setup
    # Sets up the cloud postgresql DB
    sudo /usr/sbin/euca_conf --initialize

    # For convenience, make the logs accessible to everyone
    sudo chmod -R a+rw /var/log/eucalyptus/

Step 8: Start the your cloud's components
-----------------------------------------

Start the components in this order:

    sudo service eucalyptus-cloud start
    sudo service eucalyptus-cc cleanstart
    sudo service eucalyptus-nc start

    # Tail the Cloud Controller (CLC) logs
    tail -f /var/log/eucalyptus/cloud-output.log

Your CLC is now starting up, this will take 1-2 minutes. 
Just look at the `cloud-output.log` file with the `tail -f` command above and, at some point, everything will be done and no new messages will appear. 
The last messages in cloud-output.log look like this for me.

                              |
                              |   component -- ENABLED
                              | -----------------_________________________________________________________
                              | -----------------|  Detected Interfaces                                  |
                              | -----------------|#######################################################|
                              | 
                              |   br0 -- [/10.1.0.1/24 [/10.1.0.255]]
                              |   br0 -- /10.1.0.1
                              |   lo -- [/127.0.0.1/0 [null]]
                              |   lo -- /127.0.0.1
    2013-03-13 20:15:11  INFO | Updated local host information:   Host 10.1.0.1 #13 /10.1.0.1 coordinator=10.1.0.1 booted db:synched(synced) dbpool:ok started=1363220051525 [/10.1.0.1]
    2013-03-13 20:15:11  INFO | Updated changed local host entry: Host 10.1.0.1 #11 /10.1.0.1 coordinator=10.1.0.1 booted db:synched(synced) dbpool:ok started=1363220051525 [/10.1.0.1]

Step 9: Register you cloud components
-------------------------------------

Now, you can register your cloud components: Walrus (Amazon S3 alternative), Storage Controller (provides Amazon-like EBS volumes), Cluster Controller and Node Controller. 
Again, all the cloud components will run on your local machine.
If you want to build an actual Eucalyptus cloud, distributed on many machines, then more pain will be required and this article does not address any ways of alleviating it :)
I can tell you that, if you try it, make sure you have the Storage Controller and Cluster Controller running on the same machine. 
I was not able to separate the two. 
(On the other hand, maybe you can figure it out.)

Some pre-registration prep-work first:

    # First, reset your root password
    sudo passwd

    # Second, generate an SSH key for the root account
    who=root

    if sudo su -c "test ! -f /root/.ssh/id_rsa"; then
        sudo su -c 'ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ""'
    fi
    sudo su -c "ssh-copy-id root@$addr"

Register your components:

    sudo /usr/sbin/euca_conf --register-walrus --partition walrus \
      --host 10.1.0.1 --component walrus-10.1.0.1

    sudo /usr/sbin/euca_conf --register-cluster --partition cluster01 \
      --host 10.1.0.1 --component cc-10.1.0.1

    sudo /usr/sbin/euca_conf --register-sc --partition cluster01 \
      --host 10.1.0.1 --component sc-10.1.0.1

    sudo /usr/sbin/euca_conf --register-nodes "10.1.0.1"

Now, list the components:

    sudo euca_conf --list-clouds
    sudo euca_conf --list-clusters
    sudo euca_conf --list-nodes
    sudo euca_conf --list-walrus
    sudo euca_conf --list-sc

The output should be similar to this:

    warning: No credentials found; attempting local authentication
    CLOUDS  eucalyptus  10.1.0.1  10.1.0.1  ENABLED {}
    warning: No credentials found; attempting local authentication
    CLUSTER cluster01       cc-10.1.0.1     10.1.0.1                  ENABLED{}
    warning: No credentials found; attempting local authentication
    NODE  10.1.0.1  cc-10.1.0.1
    warning: No credentials found; attempting local authentication
    WALRUS  walrus          walrus-10.1.0.1 10.1.0.1                  ENABLED{}
    warning: No credentials found; attempting local authentication
    STORAGECONTROLLER cluster01       sc-10.1.0.1     10.1.0.1                  BROKEN  {}

Notice that the Storage Controller is BROKEN! Oh no, let's fix that soon. 
**NOTE:** You can now re-enable your internet connection.

Step 10: Get your Eucalptus admin credentials
---------------------------------------------

In order to administer the cloud using the euca2ools commands, which we installed in the requirements phase, you need to first fetch your credentials from Eucalyptus and then put them in your shell's environment using the "source" command.

    userid=`id -u`
    groupid=`id -g`

    # Fetch the credentials
    sudo /usr/sbin/euca_conf --debug --get-credentials admin.zip
    sudo chown $userid:$userid admin.zip

    # Store your Eucalyptus credentials in your shell's environment.
    mkdir -p credentials
    unzip admin.zip -d credentials

    . credentials/eucarc

Ensure that your credentials work by running a command from the same terminal you ran the `. credentials/eucarc` command in.

    euca-describe-services -E

**WARNING:** If you close the terminal in which you executed the `. credentials/eucarc` command, then you need to re-execute it in another terminal in order to be able to use the euca2ools commands to manage the cloud from that new terminal.

Step 11: Fix the Storage Controller in your cloud
-------------------------------------------------

The Storage Controller manages EBS volumes for your cloud instances and needs to be told what mode to operate in (DAS or Overlay).
Also, you need to adjust the name of the `tgt` service in Ubuntu since Eucalyptus expects it to be `tgtd`. 
Fix Eucalyptus `tgt` issue:

    sudo service tgt stop
    sudo mv /etc/init/tgt.conf /etc/init/tgtd.conf
    sudo mv /etc/init.d/tgt /etc/init.d/tgtd
    sudo service tgtd start

Set the SC to 'overlay' mode:

    sc=`euca-describe-properties | grep blockstoragemanager | cut -f 2`
    euca-modify-property -p $sc=overlay

List the components. It should take less than a minute for the SC to be in the ENABLED state (you will see it as DISABLED for a while).

    sudo euca_conf --list-sc

Now, once the SC is enabled, check the cloud's availability to see how many instances you can start:

    euca-describe-availability-zones verbose

You should see a line like this (depending on your euca2ools version), which would mean you can launch two m1.small instances (1 VCPU, 512MB of RAM, 5GB of ephemeral storage):

    AVAILABILITYZONE       |- m1.small 0002 / 0002   1    512     5

Step 12: Install an OS image in Eucalyptus
------------------------------------------

Now, we need an OS image that we can boot a VM with, and the easiest way of installing an image is to use the euare-\* commands. 
First, we have to install a newer euca2ools version from Github:

    wget https://github.com/eucalyptus/euca2ools/archive/2.1.3.zip

    unzip euca2ools-2.1.3.zip -d .

    cd euca2ools-2.1.3/
    python setup.py build
    su -c 'python setup.py install'
    cd -

Then we can install a Debian cloud image (downloading the image will take a few minutes):

    wget http://emis.eucalyptus.com/starter-emis/euca-debian-2011.07.02-x86_64.tgz
    eustore-install-image -b debianbucket -t euca-debian-2011.07.02-x86_64.tgz -k kvm -s "debian" -a x86_64

Now, list the images, and ensure the Debian image is there:

    euca-describe-images

The euca-describe-images output should be similar to this:

    IMAGE  eki-5B193CB9  debianbucket/vmlinuz-2.6.28-11-generic.manifest.xml 434350321633  available private   x86_64  kernel      instance-store
    IMAGE emi-A8AD36BC  debianbucket/euca-debian-2011.07.02-x86_64.manifest.xml 434350321633  available private   x86_64  machine eki-5B193CB9  eri-F0CD3713    instance-store
    IMAGE eri-F0CD3713  debianbucket/initrd.img-2.6.28-11-generic.manifest.xml  434350321633  available private   x86_64  ramdisk   instance-store

We will use the EMI-xxxxxxxx number to boot a Debian instance later.

Step 13: Run your VM ([Zboara puiule... Zboara!](http://www.youtube.com/watch?v=hZum-Vliyjo))
--------------------

First, generate a SSH key that Eucalyptus can inject in the VM so you can use that same key to login into the VM later.

    # Generate SSH key (mykey)
    ssh-keygen -f mykey -t rsa -N ""

    # Add SSH key to Eucalyptus using euca-add-keypair
    euca-add-keypair mykey >mykey.private
    chmod 0600 mykey.private

Second, run the VM:

    # Start KVM for Intel
    sudo modprobe kvm_intel
    # Or start KVM for AMD
    sudo modprobe kvm_amd

    # Get the first EMI in the list of images (you only have one at this point)
    emi=`euca-describe-images | grep IMAGE | grep emi-........ -o | head -n 1`

    # Run an instance
    euca-run-instances -k mykey -t m1.small $emi

Look at logs and/or at the VM's console output:

    # Use -f if you'd like and Ctrl-C to exit
    tail /var/log/eucalyptus/nc.log

    # Check out console output from VM
    inst=`euca-describe-instances | grep running | head -n 1 | cut -f 2`
    euca-get-console-output $inst

Third, login and have fun:

    # Get the instance's IP
    inst=`euca-describe-instances | grep running | cut -f 4`

    # Remove a previous host key (if any) at that address
    ssh-keygen -R $inst &>/dev/null

    # SSH into the instance
    ssh -i mykey.private root@$inst

Step 14: Attach an EBS volume to your Eucalyptus instance
---------------------------------------------------------

It took me a while to figure out that you need to set the `USE_VIRTIO_DISK` flag to 1 in `eucalyptus.conf`, for volumes to work in KVM, but you already have this set in your eucalyptus.conf, if you overwrote it with mine. 
Create a 5GB volume:

    euca-create-volume --zone cluster01 -s 5

Attach it to the instance:

    inst=`euca-describe-instances | grep running | head -n 1 | cut -f 2`
    vol=`euca-describe-volumes | grep available | head -n 1 | cut -f 2`

    euca-attach-volume -i $inst -d vda $vol

Check whether it's attached:

    # login into the instance, as instructed above.

    #
    # inside the instance
    # 

    # look for messages related to the new 'vda' block device
    cat /var/log/kern.log | grep vda

Play with the volume:

    #
    # inside the instance
    #

    mkfs.ext2 /dev/vda
    mkdir /stuff
    mount /dev/vda /stuff
    echo "foobar" >/stuff/hello
    umount /stuff

Detach and reattach and make sure stuff is still there:

    #
    # inside the instance
    #

    # If you haven't, unmount the volume
    umount /stuff

    #
    # outside the instance
    #
    vol=`euca-describe-volumes | grep in-use | head -n 1 | cut -f 2`

    euca-detach-volume $vol

    # Wait for a second for the volume to attach

    # Reattach the volume
    inst=`euca-describe-instances | grep running | head -n 1 | cut -f 2`
    vol=`euca-describe-volumes | grep available | head -n 1 | cut -f 2`

    euca-attach-volume -i $inst -d vda $vol

    # Now mount the volume back, and check that 
    # the 'hello' file is still there

Finally, just detach the volume or stop the instance.

    vol=`euca-describe-volumes | grep in-use | head -n 1 | cut -f 2`
    euca-detach-volume $vol

    inst=`euca-describe-instances | grep running | cut -f 2`
    euca-stop-instances $inst
    euca-terminate-instances $inst

Question: Why isn't the internet working in my instance?
--------------------------------------------------------

I think this has to do with the fact I setup Eucalyptus to bind to the `br0` bridge, which is not connected to the Internet. 
I will write an appendix on how to fix this soon. 
I suspect there should be a way to bind Eucalyptus to `wlan0` or `eth0` in MANAGED-NOVLAN mode.

 > This post used to be at `http://alinush.org/2013/02/19/how-to-compile-and-install-eucalyptus-3-2-0-on-ubuntu-12-0412-10-from-github-sources-cloud-in-a-box/`

