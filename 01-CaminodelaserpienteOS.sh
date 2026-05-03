#!/bin/sh
# CaminodelaserpienteOS/, is a GNU/Linux distributed OS | Debian Trixie implementation powered by LIDSOL mirrors. 
# \section{Build}

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
    USER_NAME="snaker"
    RANDOM_DIGIT1=$((RANDOM % 10))
    RANDOM_DIGIT2=$((RANDOM % 10))
    SUFFIX1="${RANDOM_DIGIT1}"
    SUFFIX2="${RANDOM_DIGIT2}"
    LUKS_NAME="CaminodelaserpienteOS_GNU_Linux_Debian_Trixie_crypt_luks" # _7${SUFFIX1}${SUFFIX2}"      #Nombre del contenedor cifrado mapeado
    VG_NAME="CaminodelaserpienteOS_GNU_Linux_Debian_Trixie_vg_lvm" # _7${SUFFIX1}${SUFFIX2}"            #Nombre del Volume Group (Grupo de Volúmenes)
    LV_ROOT_NAME="CaminodelaserpienteOS_GNU_Linux_Debian_Trixie_lvm_root" # _7${SUFFIX1}${SUFFIX2}"     #Nombre del Logical Volume para la raíz (/)
    LV_HOME_NAME="CaminodelaserpienteOS_GNU_Linux_Debian_Trixie_lvm_home" # _7${SUFFIX1}${SUFFIX2}"     #Nombre del Logical Volume para /home

    cat <<EOF > /etc/apt/sources.list
    deb https://lidsol.fi-b.unam.mx/debian/ trixie main contrib non-free non-free-firmware
    deb-src https://lidsol.fi-b.unam.mx/debian/ trixie main contrib non-free non-free-firmware
EOF

    log "Instalando herramientas necesarias en el entorno Live ..."
    apt update && apt install -y dosfstools e2fsprogs parted gdisk arch-install-scripts \
    debootstrap cryptsetup lvm2 btrfs-progs xfsprogs util-linux -y --no-install-recommends --no-install-suggests

    log " === Discos Detectados ==="
    lsblk -dno NAME,SIZE,MODEL | grep -v "loop"
    read -p "Escribe el nombre del dispositivo (ej: sda, vda, nvme0n1): " DISCO
    DEVICE="/dev/$DISCO"
    if [ ! -b "$DEVICE" ]; then echo "Error: $DEVICE no existe."; exit 1; fi
    read -p "¡ADVERTENCIA! Se borrará TODO en $DEVICE. ¿Seguro? (s/N): " CONFIRM
    [[ "$CONFIRM" != "s" ]] && exit 1

    log "Limpiando el disco ..."
    umount -Rf /mnt 2>/dev/null || true
    swapoff -a 2>/dev/null || true
    vgchange -an vg_lvm 2>/dev/null || true
    wipefs -a "$DEVICE"
    sgdisk --zap-all "$DEVICE"

    log "Creando particiones con parted ..."
    parted -s "$DEVICE" mklabel gpt
    parted -s "$DEVICE" mkpart primary fat32 1MiB 513MiB
    parted -s "$DEVICE" set 1 esp on
    parted -s "$DEVICE" mkpart primary ext4 513MiB 2561MiB
    parted -s "$DEVICE" mkpart primary 2561MiB 100%
    partprobe "$DEVICE"
    sleep 2
    [[ $DEVICE =~ [0-9]$ ]] && PREFIX="${DEVICE}p" || PREFIX="${DEVICE}" # Detectar sufijo correcto (para nvme0n1p1 o sda1)
    P1="${PREFIX}1" # EFI
    P2="${PREFIX}2" # BOOT
    P3="${PREFIX}3" # LUKS

    log "Configurando LUKS en $P3 ..."
    cryptsetup luksFormat "$P3"
    cryptsetup open "$P3" "$LUKS_NAME"

    log "Creando Volúmenes Lógicos (LVM) ..."
    pvcreate /dev/mapper/"$LUKS_NAME"
    vgcreate "$VG_NAME" /dev/mapper/"$LUKS_NAME"
    lvcreate -L 65536MB "$VG_NAME" -n "$LV_ROOT_NAME"
    lvcreate -l 100%FREE "$VG_NAME" -n "$LV_HOME_NAME"

    log "Formateando particiones ..."
    mkfs.vfat -F 32 "$P1"
    mkfs.ext4 -F "$P2"
    mkfs.btrfs -f /dev/"$VG_NAME"/"$LV_ROOT_NAME"
    mkfs.xfs -f /dev/"$VG_NAME"/"$LV_HOME_NAME"

    log "Configurando subvolumen Btrfs ..."
    umount -R /mnt 2>/dev/null || true
    UUID_BTRFS=$(blkid -s UUID -o value /dev/"$VG_NAME"/"$LV_ROOT_NAME")
    mount -t btrfs -o uuid="$UUID_BTRFS" /mnt || mount /dev/"$VG_NAME"/"$LV_ROOT_NAME" /mnt
    sleep 1
    btrfs subvolume create /mnt/@ 2>/dev/null || true
    umount /mnt

    log "Montando estructura de directorios ..."
    mount -t btrfs -o subvol=@,uuid="$UUID_BTRFS" /mnt || mount -o subvol=@ /dev/mapper/"$VG_NAME"-"$LV_ROOT_NAME" /mnt
    mkdir -p /mnt/boot /mnt/home
    mount "$P2" /mnt/boot
    mount /dev/mapper/"$VG_NAME"-"$LV_HOME_NAME" /mnt/home
    mkdir -p /mnt/boot/efi
    mount "$P1" /mnt/boot/efi

    log "Instalando sistema base Debian Trixie ..."
    debootstrap --arch amd64 --variant=minbase trixie /mnt https://lidsol.fi-b.unam.mx/debian/

    log "Generando fstab y crypttab ..."
    genfstab -U /mnt | tee /mnt/etc/fstab
    UUID_LUKS=$(blkid -s UUID -o value "$P3")
    echo "${LUKS_NAME} UUID=$UUID_LUKS none luks,discard" | tee /mnt/etc/crypttab

    log "Preparando entorno Chroot ..."
    for i in /dev /dev/pts /proc /sys /run; do mount -B $i /mnt$i; done
    # Verificar que 02-CaminodelaserpienteOS.sh existe en el directorio actual
    if [ ! -f "02-CaminodelaserpienteOS.sh" ]; then
        echo "Error: 02-CaminodelaserpienteOS.sh no se encuentra en este directorio."
        exit 1
    fi
    cp 02-CaminodelaserpienteOS.sh /mnt/tmp/02-CaminodelaserpienteOS.sh
    chmod +x /mnt/tmp/02-CaminodelaserpienteOS.sh
    echo "Entrando a Chroot para finalizar configuración ..."
    chroot /mnt /usr/bin/env bash /tmp/02-CaminodelaserpienteOS.sh

    log "Copiando herramientas a la home del usuario ..."
    SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    mkdir -p "/mnt/home/$USER_NAME/CAMINODELASERPIENTE"
    cp -r "$SCRIPT_PATH/." "/mnt/home/$USER_NAME/CAMINODELASERPIENTE/"
    chroot /mnt chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME/CAMINODELASERPIENTE"

    log "Limpieza post-CHROOT ..."
    umount -l /mnt/dev/pts /mnt/dev /mnt/proc /mnt/sys /mnt/run 2>/dev/null || true
    umount /mnt/boot/efi /mnt/boot /mnt/home /mnt 2>/dev/null || true
    vgchange -an "$VG_NAME" 2>/dev/null || true
    cryptsetup close "$LUKS_NAME" 2>/dev/null || true
}

main "$@"
