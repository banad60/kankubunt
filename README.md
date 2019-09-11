# kankubunt - cause it's with kanku ... und bunt too

kankubunt was needed, to end the pale age of [kanku](https://github.com/M0ses/kanku).
And kankubunt completes kanku in its ability for creating and developing
virtual-machines (VMs) on the [libvirt](https://libvirt.org)/[qemu](https://www.qemu.org/) virtualization-host.

As side-effect, kanku can now work with an localy installed ubuntu-18.04, so
you do not need any connectivity to the suse-OBS-server for an image. After the
automatic installation of ubuntu as local source-image for kanku, you can fork
this and work on these clones with kanku, revision and then release it. The
target groups for this application are sysadmins, power- and advanced-users.

Attantion! This project is unfinished! For now it is has the state of an running
work-example, to show what is possible with kanku and how different it can be
used, including embedding its created VMs to different network-infrastructures.

## Quick Start

For kankubunt to work, some requirements are necessary:

### Get kanku

- First you need to install [kanku](https://github.com/M0ses/kanku).

- Make sure, the virt-utilities `virt-install` and `guestfs-tools` are installed on the host-machine also.

- You have to have sudo-rights with `ALL = (ALL:ALL) NOPASSWD: ALL`.

### Setup the KVM default-network configuration

- to get the examples running, have these networks:
```
libvirt-network                    : 192.168.122.0/24
libvirt-host                       : 192.168.122.1
libvirt-dhcp-range                 : 192.168.122.64 - 192.168.122.254

host-bridge network                : 192.168.22.0/24
```
accessible.

- or edit/create inifiles under `config/` plus there defaults `config/defaults/`.

### Commands

```
./kankubunt-status           : show the status of kankubunt resorces

./view-active-conf           : show the activated configuration
./view-inifiles              : show inifiles at configs/
./view-kankubunt-sources     : show resorces at ~/.cache/kanku
./view-libvirt-images        : show resorces at /var/lib/libvirt/images
./view-VMs                   : show VMs and there states

./install-local-kanku-source : install the local kanku-source image.

./reconf-kanku-vm              : reconfig your VM you want work with.
      -f|--file <inifile>        : relative path to inifile (config/*)
      dhcp-default               : libvirt default-network as dhcp-client (isolated)
      dhcp-bridge                : libvirt host-bridge (dhcp-client on extern dhcp)
      dhcp-bridge-mac            : libvirt host-bridge-mac (dhcp-client on extern dhcp/bootp)
      static-default             : libvirt default-network with static ip (isolated)
      static-bridge              : libvirt host-bridge with static ip

./revision-kanku-vm            : revision the kanku-vm one level higher an use that image

./reset-kanku-vm               : reset kanku-vm, delete all revisions, go to r1

./reset-ini                    : reset kanku-vm, delete all revisions, go to r0

./release-kanku-vm             : release the kanku-vm and dispatch from kanku

./define-local-kanku-source-vm : define a kanku-source-image-vm (for debug only)



./isOnline <ip> <port>         : helper (for debug only)

./mkpath-executable            : helper (for debug only)



```

### First run

With the run of the kankubunt command `./install-local-kanku-source`, at first
the ubuntu-source-image will be installed automaticly. This clould take a while,
depending on your network-bandwith and on your hardware as well. An normal time
for the installation-prozess of ubunt

And for sure on
ubuntu, because the installation is an online-prozess and sometimes the
ubuntu-mirror is slow, but with that you must live on. Once ubuntu is installed
as the kanku-soure, the next prozesses run all localy and fast. There is no need
to do this again, sinze you want reinstall.

The base source-image is named `u1804us.qcow2` and is located in your
`~/.config/kanku` directory.


## Examples:

```
./install-local-kanku-source static-bridge

./reconf-kanku-vm dhcp-default

./reconf-kanku-vm static-default

./reconf-kanku-vm -f configs/KankuFile_dhcp-bridge-mac_DHCP-BRIDGE-MAC-vm.ini

./revision-kanku-vm

./release-kanku-vm

```

## NO WARRANTY!!

If you are use this unfinished version at this state and release VMs,
overwriting of older VM-images may be possible. So be careful by this and be
always sure to have proper backups of the "real" productive VM before you do
another `./reconf-kanku-vm` !!

### Helpful Notes:

kankubunt is developed on [openSUSE-15.1](https://de.opensuse.org/Portal:15.1) and [ubuntu-18.04](http://releases.ubuntu.com/18.04/)

The benefit on openSUSE: kanku comes from there and it is maintained and
automatically updated by there backend-developers. The installation of kanku and
all parts of it, comes with the package `kanku-common`.

On ubuntu there is no package for [kanku](https://github.com/M0ses/kanku), so
you have to look at your own that kanku is up to date an work properly. But
with a little more expenditure of time it is also possible, to run kanku on an
ubuntu-KVM-host ... and after this kanku runs there with no problems also.

### Own Inifiles:

However, if the prepared network-configurations of kankubunt are not working
at your network:

- Try it with your own inifiles.

There are two inifiles. The default one under `configs/defaults/*` and it’s
variable clone, located at `configs/*` .

When you do a `./reconf-kanku-vm -f inifile`, then this inifile is symlinked
to `configs/KankuFile.ini`, so the application can find it.

You can configure as many inifiles, as you want. Look to the others,
to see more about the format-terms.

### kankushare:

- The `fakeroot/` directory is prepeared as local storage for upload-files to your VM-projects.

- Under `/tmp/kanku` in the VM, the (this) kankubunt root-directory is mounted read only.

This first version of kankubunt has an ubuntu18.04LTS as source only and there
is no switch to another operating-system (may be in the future).

### Apology

the coder is a native born old Bavarian, who is in love with denglish hopelessly.

