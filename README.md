# Linux Shell Toolbox

Following steps are already on [arch
wiki](https://wiki.archlinux.org/title/Installation_guide) page, but they are
simplified for my personal use. Feel free to use them for your own but beware
of differences between my system and yours. For example, if you have NVME
storage drives on your laptop, you system might name your drives `nvme0n1` as
well, but they also might be named like `sda`, etc. So you need to customize
these steps too.

I don't regularly reinstall Arch Linux, I do it once in two or three years, not
because it fails to be as operative as it was back in its first day, but
because I make my systems a mess time to time. That is, I make mistakes which
Windows users might not be able to do so. And yes, Linux users might have this
habbit of cleaning their system by reinstalling Linux time to time, it's
because they usually learn to use it more appropriately and more expertly in
time which is rare between Windows users. And of course the reason to all of
this is due to the complexity of Linux systems and how long it takes to know
them very well, which for me it seems to take forever.

## Installation

First you need to make sure that **Secure Boot** is disabled on your system.

Then, check if Arch Linux live booted in UEFI mode. If not, reboot and change
boot mode on your system:

```sh
ls /sys/firmware/efi/efivars
```

Based on my experience, wireless devices seem to be blocked by `rfkill` on Arch
Linux live boot, so you need to check if they are blocked and unblock them if
necessary:

```sh
rfkill list             # check if wlan0 is blocked
rfkill unblock all      # specify wlan0 or all to unblock
ip link set wlan0 up    # also set the interface up for use
```

When interface is prepared, connect to a wireless using `iwctl` by following
these commands:

```sh
iwctl station wlan0 scan
iwctl station wlan0 get-networks
iwctl station wlan0 connect <BSSID>     # replace BSSID with access point name
dhclient                                # just to make sure you got an ip
ping archlinux.org                      # check if you're connected to network
```

After you're connected to the network, update your system's time:

```sh
timedatectl set-ntp true
```

Now partition your system:

```sh
fdisk /dev/nvme0n1
```

Make sure `fdisk` is set on **gpt partition table**. If it's not, just hit
**g**. Assuming you have 1TB of NVME storage drive, partition as follows:

* uefi: /dev/nvme0n1p1 (1G)
* swap: /dev/nvme0n1p2 (2G)
* lvm:  /dev/nvme0n1p3 (rest)

Make file systems:

```sh
mkfs.fat -F 32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
```

Don't format the LVM partition just yet.

Encrypt the file system:

```sh
cryptsetup luksFormat /dev/nvme0n1p3
cryptsetup luksFormat /dev/nvme0n1p4
```

Then decrypt the partitions to include them in fstab:

```sh
cryptsetup open --type luks /dev/nvme0n1p3 root_storage
cryptsetup open --type luks /dev/nvme0n1p4 home_storage
```

At this point you can setup LVM:

```sh
pvcreate /dev/mapper/root_storage
vgcreate vg_system /dev/mapper/root_storage
lvcreate -L 100GB vg_system -n lv_root
lvcreate -L 500GB vg_system -n lv_home
vgdisplay
lvdisplay
modprobe dm_mod
vgscan
vgchange -ay
```

Then create filesystem on LVM partitions:

```sh
mkfs -t ext4 /dev/vg_system/lv_root
mkfs -t ext4 /dev/vg_system/lv_home
```

Mount partitions accordingly:

```sh
mount /dev/vg_system/lv_root /mnt
mount --mkdir /dev/nvme0n1p2 /mnt/boot
mount --mkdir /dev/vg_system/lv_home /mnt/home
swapon /dev/nvme0n1p2
```

Now that partitions are ready to be used, but before installing the Linux
itself, there's a small chance that `pacman` has outdated keyrings. To make
sure no errors will occur during installation, just update keyring:

```sh
pacman -Sy archlinux-keyring
```

Now Linux packages can be installed on the mounted partition:

```sh
pacstrap /mnt base linux linux-headers linux-firmware linux-hardened sof-firmware amd-ucode amd-headers grub efibootmgr
```

You might also need these packages:
**NOTE:** there will be Gnome Desktop installed on your system afterwards.

```sh
pacstrap /mnt acpi amd-ucode amdvlk amvlk archlinux-keyring automake base base-devel bash bc bind binutils bison boost boost-libs bpf bpftrace bridge-utils bzip2 ca-certificates cargo ccache clang cmake cmatrix coreutils ctags cups curl docker doxygen eog evince fakeroot ffmpeg firewalld flatpak fprintd gcc gdb git github-cli gnome gnupg gperf gperftools grep grub gstreamer gtest gzip htop inettools jq jsoncpp kicad kicad-library less lesspipe linux linux-api-headers linux-firmware linux-hardened-headers linux-headers llvm llvm-libs lsof lynx lz4 make man man-db man-pages mdadm mesa mesa-utils meson mirro-rs mkinicpio mtr mutt nasm ncurses neovim neovim-lspconfig net-tools networkmanager nftables nmap ntfs-3g nvim openssh openssl openvpn pacman pacman-mirrorlist pacutils pam pambase patch patchutils perf picocom pinentry pkgconf plantuml protobuf protobuf-c python qemu-base qemu-docs qemu-system-aarch64 qemu-system-arm qemu-system-arm-firmware qemu-system-riscv qemu-system-riscv-firmware qemu-system-x86 qemu-system-x86-firmware qemu-tools qt5-base qt6-base rapidjson rpcsvc-proto rsync samba sed shadow shellcheck shellharden smbclient strace sudo systemd systemd-libs systemd-sysvcompat tar telegram-desktop texlive-basic texlive-bibtexextra texlive-fontsextra texlive-fontsrecommended texlive-formatsextra texlive-latex texlive-latexextra texlive-latexrecommended texlive-pictures texlive-plaingeneric tmux traceroute ttf-sourcecodepro-nerd tzdata uboot-tools unrar unzip urlscan usbutils util-linux util-linux-libs valgrind vim virtualbox virtualbox-guest-iso virtualbox-guest-utils virtualbox-host-modules-arch vlc vulkan-headers vulkan-icd-loader vulkan-mesa-layers vulkan-radeon wget which wireless_tools wpa_supplicant xsel xz zip
```

You should probably install these packages later as they will not be available now:

```sh
aircrack-ng bash-completion g++ google-chrome steam wine winetricks zoom
```

Then generate file system table for next reboot:

```sh
genfstab -U /mnt >> /mnt/etc/fstab
```

If partitions are locked by `cryptsetup`, then make sure the root partition is
not specified by **UUID**, but as `/dev/mapper/root_storage`. This is because
the encrypted parition should be decrypted first and fstab should know where
should be the decrypted path.

But make sure the rest of encrypted partitions are written with **UUID** of
decrypted paths.

When using encrypted drives, you should also write the following records into
`/etc/crypttab`:

```sh
home_storage UUID=1234-abcd none luks
```

There should not be root partition address here because initcpio should already
be decrypting the root partition on boot, this is just for the rest of
encrypted partitions.

Now chroot into the Linux installed partition:

```sh
arch-chroot /mnt
```

Setup your time zone and verify your system time by `date` command:

```sh
ln -s /usr/share/zoneinfo/<Region>/<City> /etc/localtime
hwclock --systohc
date
```

Uncomment `en_US.UTF-8` in `/etc/locale.gen` and then execute:

```sh
locale-gen
```

Setup system language:

```sh
echo 'LANG=en_US.UTF-8' >> /etc/locale.conf
```

And your host name which will be seen on your prompt `user@hostname`:

```sh
echo '<hostname>' > /etc/hostname
```

Now this is not necessary, but it would be if you have made LVM, RAID, or LUKS
configurations, see `mkinitcpio.conf(5)`. Generally the `/etc/mkinitcpio.conf`
file should have this hook when LUKS used:

```sh
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap encrypt consolefont block filesystems fsck)
```

Then run:

```sh
mkinitcpio -P
```

This is where `amd-ucode`, `grub` and `efibootmgr` is needed so that the system
can boot:

If using encrypted drives, make sure you also include this in kernel command line `GRUB_CMDLINE_LINUX` inside `/etc/default/grub`:

```sh
GRUB_CMDLINE_LINUX="cryptdevice=UUID=1234-abcd:root_storage root=/dev/mapper/root_storage"
```

Then generate grub configurations:

```sh
grub-install --target x86_64-efi --efi-directory /boot --bootloader-id GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

Add boot parameter in `/etc/default/grub`:

```sh
cryptdevice=/dev/nvme0n1p3:vg_system
```

Create users and set passwords:

```sh
passwd
useradd -m <username>
passwd <username>
```

And give users privileges using `visudo` command, so that you won't have to log
into the `root` user anymore.

Also if this is a remote server, configure SSH so that service is on different
port and `root` login cannot be made.

You might realize that Arch Linux makes a lot of loud beeps because of PC
speaker module. To disable it, `pcspkr` driver should be blocked:

```sh
rmmod pcspkr
echo 'blacklist pcspkr' > /etc/modprobe.d/pcspkr.conf
```

You might also face problems when running a virtual machine instance,
VirtualBox complaining that module is not loaded. This is simple to fix by
loading its module:

```sh
modprobe vboxdrv
```

Now go back to live boot shell and unmount all partitions:

```sh
exit
umout -R /mnt
reboot
```

After reboot, enable desired services:

```sh
systemctl enable --now gdm
systemctl enable --now sshd
systemctl enable --now NetworkManager
systemctl enable --now bluetooth
```

