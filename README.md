# Shellbox

Combination of shell-related utilities.

## Depdencies

### System

The list of entire packages required for Fedora setup:

```sh
sudo dnf install wget proton-vpn-cli qbittorrent vsftpd gpgme-devel gnupg2-smime lua-devel compat-lua-devel notmuch-devel sqlite-devel ncurses-devel gnutls-devel lmdb-devel lz4-devel krb5-devel libasan libgsasl-devel cmake claude-code gnome-tweaks gnome-shell-extension-manager gnome-shell-extension-appindicator gnome-shell-extension-dash-to-panel gnome-extensions-app gnome-browser-connector cargo dbus-devel gdk-pixbuf2 gdk-pixbuf2-devel cairo-gobject-devel libsoup-devel javascriptcoregtk4.1-devel atk-devel rust-gdk4-devel gtk3-devel webkit2gtk4.1-devel wine steam
```

### Proton VPN

Visit Proton website to get the link. But the command is similar to:

```sh
wget "https://repo.protonvpn.com/fedora-$(cat /etc/fedora-release | cut -d' ' -f 3)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.4-1.noarch.rpm"
```

### Proton Mail Bridge

Check https://proton.me/support/install-bridge-linux-rpm-file to get the correct version:

```sh
wget https://proton.me/download/bridge/protonmail-bridge-3.22.0-1.x86_64.rpm
sudo dnf install ./protonmail-bridge-3.22.0-1.x86_64.rpm
```

### Neomutt Dependencies

```sh
sudo dnf install gpgme-devel gnupg2-smime lua-devel compat-lua-devel notmuch-devel sqlite-devel ncurses-devel gnutls-devel lmdb-devel lz4-devel krb5-devel libgsasl-devel
```

### Neomutt Configuration Flags

```sh
./configure --prefix=/usr/local --gnutls --gpgme --gss --lua --sqlite --autocrypt --lmdb --notmuch --lz4 --zlib --disable-doc --gsasl --fmemopen --with-lock=flock --locales-fix --homespool
```

