#!/bin/sh
# CaminodelaserpienteOS/, is a GNU/Linux distributed OS | Debian Trixie implementation powered by LIDSOL mirrors. 
# \section{CHroot}

set -eu

if [ "$(id -u)" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

PASO_ACTUAL=0
TOTAL_PASOS=$(grep -c "log " "$0")
TOTAL_PASOS=$((TOTAL_PASOS - 1))
log() {
    PASO_ACTUAL=$((PASO_ACTUAL + 1))
    CONTADOR=$(printf "%02d/%02d" "$PASO_ACTUAL" "$TOTAL_PASOS")
    echo "[$CONTADOR] [$(date +'%F %T')] >>> $1"
}


main() {

    export DEBIAN_FRONTEND=noninteractive
    export LANG=C
    export LC_ALL=C

    SECONDS=0
    HOSTNAME="Jarvis"
    USER_NAME="Viper"
    USER_PASS="222"
    ROOT_PASS="222"

    log "[CHroot] Configurando repositorios sources.list para apt ..."
    cat <<EOF > /etc/apt/sources.list
    deb https://lidsol.fi-b.unam.mx/debian/ trixie main contrib non-free non-free-firmware
    deb-src https://lidsol.fi-b.unam.mx/debian/ trixie main contrib non-free non-free-firmware
EOF

    log "[CHroot] Configurando teclado ..."
    apt update
    apt install -y --no-install-recommends --no-install-suggests debconf-utils locales \
    keyboard-configuration console-setup
    echo "keyboard-configuration keyboard-configuration/modelcode string pc105" | debconf-set-selections
    echo "keyboard-configuration keyboard-configuration/layoutcode string us" | debconf-set-selections
    echo "keyboard-configuration keyboard-configuration/variantcode string altgr-intl" | debconf-set-selections
    cat <<EOF > /etc/default/keyboard
    XKBMODEL="pc105"
    XKBLAYOUT="us"
    XKBVARIANT="altgr-intl"
    XKBOPTIONS=""
    BACKSPACE="guess"
EOF

    log "[CHroot] Instalando paquetes del sistema ..."
    apt install linux-image-amd64 linux-headers-amd64 grub-efi-amd64 xfsprogs btrfs-progs \
    cryptsetup cryptsetup-initramfs lvm2 systemd-sysv init network-manager wpasupplicant firmware-iwlwifi \
    intel-microcode firmware-linux firmware-linux-free firmware-linux-nonfree firmware-misc-nonfree \
    sudo openssh-server nano zstd fonts-noto-cjk fonts-noto-core -y --no-install-recommends --no-install-suggests
    # apt install iwd dbus para no usar network-manager con wpasupplicant si asi se desea.

    log "[CHroot] Configurando Locales y Teclado definitivos ..."
    sed -i '/^# es_MX.UTF-8 UTF-8/s/^# //' /etc/locale.gen
    locale-gen
    update-locale LANG=es_MX.UTF-8 LANGUAGE="es_MX:es"
    dpkg-reconfigure -f noninteractive keyboard-configuration
    setupcon --force || true
    export LANG="es_MX.UTF-8"
    export LANGUAGE="es_MX:es"
    export LC_ALL="es_MX.UTF-8"

    log "[CHroot] Configurando Zona Horaria..."
    ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
    dpkg-reconfigure -f noninteractive tzdata

    log "[CHroot] Estableciendo contraseñas..."
    echo "root:$ROOT_PASS" | chpasswd
    useradd -m -G sudo -s /bin/bash $USER_NAME
    echo "$USER_NAME:$USER_PASS" | chpasswd

    log "[CHroot] Configurando /etc/hostname, /etc/network/interfaces y /etc/NetworkManager/NetworkManager.conf ..."
    echo "$HOSTNAME" > /etc/hostname
    cat <<EOF > /etc/hosts
    127.0.0.1   localhost
    127.0.1.1   $HOSTNAME

    ::1     localhost ip6-localhost ip6-loopback
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters
EOF

    mkdir -p /etc/network && cat <<EOF > /etc/network/interfaces
    auto lo
    iface lo inet loopback
EOF

    mkdir -p /etc/NetworkManager/ && cat <<EOF > /etc/NetworkManager/NetworkManager.conf
    [main]
    plugins=ifupdown,keyfile

    [ifupdown]
    managed=true
EOF

    log "[CHroot] Creando README para: $USER_NAME..."
    cat << EOF > /home/$USER_NAME/README.txt
    ================================================================================
                                        README
    ================================================================================
    [+] CREATE SNAPSHOTS:
    ----------------------------------------------------------------------
    To generate snap:
    $ snaptime

    To return time a snap:
    $ snapretime

    [+] LINKING (Wi-Fi) network-manager (default):
    ----------------------------------------------------------------------
    1. Scan local signals:
    $ sudo nmcli device wifi list

    2. Establish a secure bond:
    $ sudo nmcli device wifi connect "SSID" password "PASS"

    3. Listar conecciones guardadas:
    $ sudo nmcli connection show

    4. Remove conecion saved:
    $ sudo nmcli connection delete "SSID"
    ----------------------------------------------------------------------
    ======================================================================
EOF

    log "[CHroot] Configurando Initramfs ..."
    echo "btrfs" >> /etc/initramfs-tools/modules
    echo "zstd" >> /etc/initramfs-tools/modules
    update-initramfs -u -k all

    log "[CHroot] Instalando GRUB ..."
    sed -i 's/GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="CaminodelaserpienteOS"/' /etc/default/grub
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub
    echo "GRUB_TERMINAL=console" >> /etc/default/grub
    echo "GRUB_PRELOAD_MODULES=\"btrfs\"" >> /etc/default/grub
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=CaminodelaserpienteOS --recheck
    grub-mkconfig -o /boot/grub/grub.cfg

    log "[CHroot] Creando Fallback UEFI ..."
    mkdir -p /boot/efi/EFI/BOOT
    cp /boot/efi/EFI/CaminodelaserpienteOS/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI

    log "[CHroot] Habilitando servicios..."
    systemctl enable ssh

    log "[CHroot] Exit ..."
    exit
}

main "$@"
