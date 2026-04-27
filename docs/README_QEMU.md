# QEMU Laboratory Environment

 [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-A42E2B?labelColor=333333&logo=gnu&logoColor=FCC624)](LICENSE) ![Linux](https://img.shields.io/badge/Kernel-Linux-ffd133?labelColor=333333&logo=linux&logoColor=FCC624) ![Debian](https://img.shields.io/badge/Debian-Trixie-265774?labelColor=333333&logo=debian&logoColor=D70A53) ![QEMU](https://img.shields.io/badge/OVMF-QEMU-FF6600?labelColor=333333&logo=qemu&logoColor=white) 

> **Virtualization workflow for CaminodelaserpienteOS | Automated disk provisioning and UEFI multi-node deployment.**

* ### License: This project is licensed under the GNU General Public License v3.0. See the [`LICENSE`](LICENSE) file for more information.

* ### Storage Provisioning:
    ```sh
    # Image creation and UEFI variables initialization
    qemu-img create -f qcow2 ~/.qemu/virtuales/base.qcow2 90G
    qemu-img create -f qcow2 ~/.qemu/virtuales/virtual.qcow2 80G
    cp /usr/share/OVMF/OVMF_VARS_4M.fd ~/.qemu/virtuales/virtual.fd
    ```

* ### Instance A: Debian Live (debian-live-13.4.0-amd64-xfce.iso)
    ```sh
    qemu-system-x86_64   -m 2G \
    -smp 1 \
    -enable-kvm \
    -cpu host \
    -name 'debian-lab' \
    -drive file=~/.qemu/imgs/debian-live-13.4.0-amd64-xfce.iso,media=cdrom,readonly=on \
    -drive file=base.qcow2,format=qcow2,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -vga virtio \
    -display gtk,gl=on \
    -device virtio-tablet-pci \
    -device virtio-balloon-pci \
    -boot d
    ```

* ### Instance B: vda
    ```sh
    qemu-system-x86_64 -m 1G \
    -smp 1 \
    -enable-kvm \
    -cpu host \
    -name 'Caminodelaserpiente-vda-Lab' \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
    -drive if=pflash,format=raw,file=virtual.fd \
    -drive file=base.qcow2,format=qcow2,if=virtio \
    -drive file=virtual.qcow2,format=qcow2,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -vga virtio \
    -display gtk,gl=on \
    -device virtio-tablet-pci \
    -device virtio-balloon-pci
    ```

* ### Instance C: vdb
    ```sh
    qemu-system-x86_64 -m 1G \
    -smp 1 \
    -enable-kvm \
    -cpu host \
    -name 'Caminodelaserpiente-vdb-Lab' \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
    -drive if=pflash,format=raw,file=virtual.fd \
    -drive file=virtual.qcow2,format=qcow2,if=virtio \
    -drive file=base.qcow2,format=qcow2,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -vga virtio \
    -display gtk,gl=on \
    -device virtio-tablet-pci \
    -device virtio-balloon-pci
    ```
