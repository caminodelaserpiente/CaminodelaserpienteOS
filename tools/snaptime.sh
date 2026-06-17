#!/bin/sh
# CaminodelaserpienteOS/, is a GNU/Linux distributed OS | Debian Trixie implementation. 
# \section{snaptime}

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

    printf "Introduce el nombre para el nuevo snapshot: "
    read -r NAME_SNAPSHOT
    if [ -z "$NAME_SNAPSHOT" ]; then
        echo "Error: El nombre del snapshot no puede estar vacío."
        exit 1
    fi
    NAME_SNAPSHOT=$(echo "$NAME_SNAPSHOT" | tr -dc '[:alnum:].-_')
    log "Nombre asignado: $NAME_SNAPSHOT"

    ROOT_DEV=$(mount | grep "on / type btrfs" | grep "subvol=/@" | awk '{print $1}')
    if [ -z "$ROOT_DEV" ]; then
        echo "Error: No se pudo detectar el dispositivo raíz Btrfs."
        exit 1
    fi
    log "Dispositivo detectado correctamente: $ROOT_DEV."

    mount "$ROOT_DEV" /mnt
    mkdir -p /mnt/snaps

    if [ -d "/mnt/snaps/$NAME_SNAPSHOT" ]; then
        echo "Error: Ya existe un snapshot con el nombre '$NAME_SNAPSHOT'."
        umount /mnt
        exit 1
    fi

    log "Creando punto de restauración: $NAME_SNAPSHOT ..."
    btrfs subvol snapshot /mnt/@ /mnt/snaps/"$NAME_SNAPSHOT"
    btrfs subvol snapshot -r /mnt/@ /mnt/snaps/"$NAME_SNAPSHOT"_inmutable

    cd ~/
    sync
    umount /mnt
    log "Snapshot creado satisfactoriamente."
}

main "$@"
