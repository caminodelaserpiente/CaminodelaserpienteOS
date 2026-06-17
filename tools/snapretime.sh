#!/bin/sh
# CaminodelaserpienteOS/, is a GNU/Linux distributed OS | Debian Trixie implementation. 
# \section{snapretime}

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
    
    ROOT_DEV=$(mount | grep "on / type btrfs" | grep "subvol=/@" | awk '{print $1}')
    if [ -z "$ROOT_DEV" ]; then
        echo "Error: No se pudo detectar el dispositivo raíz Btrfs."
        exit 1
    fi
    log "Dispositivo detectado correctamente: $ROOT_DEV."

    mount "$ROOT_DEV" /mnt

    echo "----------------------------------------"
    echo "Snapshots disponibles para restaurar:"
    ls -1 /mnt/snaps
    echo "----------------------------------------"
    
    printf "Introduce el nombre exacto del snapshot al que deseas regresar: "
    read -r SNAP_DESTINO

    if [ ! -d "/mnt/snaps/$SNAP_DESTINO" ]; then
        echo "Error: El snapshot '$SNAP_DESTINO' no existe."
        umount /mnt
        exit 1
    fi

    log "Iniciando proceso de restauración hacia: $SNAP_DESTINO ..."
    NAME_BACKUP=$(date +'%d-%m-%Y_%H-%M')
    BACKUP_SISTEMA_ACTUAL="/mnt/snaps/@restauracion_$NAME_BACKUP"
    
    log "Respaldando sistema actual en: $BACKUP_SISTEMA_ACTUAL"
    mv /mnt/@ "$BACKUP_SISTEMA_ACTUAL"
    btrfs subvol snapshot /mnt/snaps/"$SNAP_DESTINO" /mnt/@

    cd ~/
    sync
    umount /mnt
    
    log "Sistema restaurado satisfactoriamente."
    echo ""
    echo "=========================================================="
    echo "¡ADVERTENCIA! El cambio se aplicará en el próximo reinicio."
    echo "Por favor, reinicia el sistema (sudo systemctl reboot) ahora."
    echo "=========================================================="
}

main "$@"
