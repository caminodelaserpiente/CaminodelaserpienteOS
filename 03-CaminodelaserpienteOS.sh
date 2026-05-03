#!/bin/sh
# CaminodelaserpienteOS/, is a GNU/Linux distributed OS | Debian Trixie implementation powered by LIDSOL mirrors. 
# \section{Packages}

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
USER_NAME="snaker"

ROOT_DEV=$(mount | grep "on / type btrfs" | grep "subvol=/@" | awk '{print $1}')
if [ -z "$ROOT_DEV" ]; then
    echo "Error: No se pudo detectar el dispositivo raíz Btrfs."
    exit 1
fi
log "Dispositivo detectado correctamente: $ROOT_DEV."

log "Crear punto de restauración no.1 ..."
mount "$ROOT_DEV" /mnt
mkdir -p /mnt/snaps
btrfs subvol snapshot /mnt/@ /mnt/snaps/@000-rescate
btrfs subvol snapshot /mnt/@ /mnt/snaps/@000-rescateinmutable -r
cd ~/
sync
umount /mnt

log "Instalando herramientas ..."
apt install passt \
 htop \
 git \
 bluez ovmf qemu-system-x86 qemu-utils qemu-system-gui -y --no-install-recommends --no-install-suggests
#  aardvark-dns \
#  podman \
#  podman-compose \
#  uidmap 
# usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER_NAME
sudo usermod -aG kvm $USER_NAME

mkdir -p /home/$USER_NAME/.qemu
mkdir -p /home/$USER_NAME/.qemu/imgs
mkdir -p /home/$USER_NAME/.qemu/virtuales
cp /usr/share/OVMF/OVMF_VARS_4M.fd /home/$USER_NAME/.qemu/virtuales/virtual.fd
cd /home/$USER_NAME/.qemu/virtuales/
qemu-img create -f qcow2 base.qcow2 90G
qemu-img create -f qcow2 virtual.qcow2 80G
sudo chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.qemu
cd ~/

log "Crear punto de restauración n.2 ..."
mount "$ROOT_DEV" /mnt
btrfs subvol snapshot /mnt/@ /mnt/snaps/@001-servidor
btrfs subvol snapshot /mnt/@ /mnt/snaps/@001-servidorinmutable -r
cd ~/
sync
umount /mnt

log "Instalando GNOME ..."
apt update
apt install -y --no-install-recommends --no-install-suggests \
 power-profiles-daemon \
 gnome-session \
 gnome-shell \
 gnome-control-center \
 gnome-console \
 ffmpegthumbnailer \
 libgdk-pixbuf2.0-bin \
 gdm3 \
 fonts-noto-color-emoji \
 fonts-noto-extra \
 fonts-freefont-ttf \
#  loupe \
#  showtime \
#  nautilus \

log "Crear punto de restauración n.2 ..."
mount "$ROOT_DEV" /mnt
btrfs subvol snapshot /mnt/@ /mnt/snaps/@002-desktop
btrfs subvol snapshot /mnt/@ /mnt/snaps/@002-desktopinmutable -r
cd ~/
sync
umount /mnt

log "Descargando software ..."
apt install wget curl -y --no-install-recommends --no-install-suggests
apt install --reinstall ca-certificates -y
mkdir -p /home/$USER_NAME/software
cd /home/$USER_NAME/software
wget -O vscode_latest.deb 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64'
wget https://repo.librewolf.net/pool/librewolf-149.0.2-2-linux-x86_64-deb.deb
#URL=$(curl -sI https://github.com/beekeeper-studio/beekeeper-studio/releases/latest | grep -i location | cut -d ' ' -f 2 | tr -d '\r')
#VERSION=$(basename $URL)
#DEB_URL="https://github.com/beekeeper-studio/beekeeper-studio/releases/download/${VERSION}/beekeeper-studio_${VERSION#v}_amd64.deb"
#wget "$DEB_URL" -O beekeeper-studio.deb
#wget -P ~/.qemu/imgs https://lidsol.fi-b.unam.mx/debian-cd/13.4.0-live/amd64/iso-hybrid/debian-live-13.4.0-amd64-xfce.iso
#git clone https://github.com/ggml-org/llama.cpp.git
#wget https://github.com/ankitects/anki/releases/download/25.09/anki-launcher-25.09-linux.tar.zst
#wget https://mirrors.rit.edu/CTAN/systems/texlive/Images/texlive2026.iso.sha512
#wget https://mirrors.rit.edu/CTAN/systems/texlive/Images/texlive2026.iso.md5
#wget -c https://mirrors.rit.edu/CTAN/systems/texlive/Images/texlive2026.iso
sudo chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/software

log "Regresando a un punto de restauración ..."
DATENMUELL_NAME="/mnt/snaps/@verwaiste"
mount "$ROOT_DEV" /mnt
mv /mnt/@ "$DATENMUELL_NAME"
btrfs subvol snapshot /mnt/snaps/@002-desktop /mnt/@
cd ~/
sync
umount /mnt
btrfs subvolume list /

}

main "$@"
