#!/bin/sh
# CaminodelaserpienteOS/, is a GNU/Linux distributed OS | Debian Trixie implementation powered by LIDSOL mirrors. 
# \section{Ablatio}

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
USER_NAME="Viper"

ROOT_DEV=$(mount | grep "on / type btrfs" | grep "subvol=/@" | awk '{print $1}')
if [ -z "$ROOT_DEV" ]; then
    echo "Error: No se pudo detectar el dispositivo raíz Btrfs."
    exit 1
fi
log "Dispositivo detectado correctamente: $ROOT_DEV"

log "Instalando software ..."
#apt install -y --no-install-recommends --no-install-suggests \
# libreoffice-writer \
# libreoffice-impress \
# libreoffice-calc
apt install -y --no-install-recommends --no-install-suggests /home/$USER_NAME/software/vscode_latest.deb
apt install -y --no-install-recommends --no-install-suggests /home/$USER_NAME/software/librewolf-*.deb

log "Crear punto de restauración n.3 ..."
mount "$ROOT_DEV" /mnt
btrfs subvol snapshot /mnt/@ /mnt/snaps/wiederherstellungspunkt
btrfs subvol snapshot /mnt/@ /mnt/snaps/wiederherstellungspunkt_readonly -r
cd /home/$USER_NAME
sync
umount /mnt

log "Eliminando punto de restauración verwaiste ..."
mount "$ROOT_DEV" /mnt
btrfs subvolume delete /mnt/snaps/@verwaiste
cd ~/
sync
umount /mnt

}

main "$@"
