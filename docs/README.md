<!-- # CaminodelaserpienteOS/, is a GNU/Linux distributed OS | Debian Trixie implementation powered by LIDSOL mirrors. 
# \section{Manuductio celere} -->

# CaminodelaserpienteOS

 [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-A42E2B?labelColor=333333&logo=gnu&logoColor=FCC624)](LICENSE) ![Linux](https://img.shields.io/badge/Kernel-Linux-ffd133?labelColor=333333&logo=linux&logoColor=FCC624) ![Debian](https://img.shields.io/badge/Debian-Trixie-265774?labelColor=333333&logo=debian&logoColor=D70A53) ![LIDSOL](https://img.shields.io/badge/LIDSOL-UNAM-003D7C?labelColor=D59F0F&logo=data:image/svg+xml)

> Manuductio Celere pro *Debian GNU/Linux* installans: Scriptum ex fontibus *LIDSOL/UNAM* | ad *CaminodelaserpienteOS*
> . Ablatione errorum ex facto oritur ius. Hoc systema libertatem machinae et mentis petit.

* ### License: This project is licensed under the GNU General Public License v3.0. See the [`LICENSE`](LICENSE) file for more information.

* ### Requirements:
    - 64GB     HDD
    - 128MB    RAM > +2GB      RAM (Recommend)

* ### Quick start:
    ```sh
    git clone https://github.com/caminodelaserpiente/CaminodelaserpienteOS.git
    cd CaminodelaserpienteOS
    chmod +x 01-CaminodelaserpienteOS.sh
    chmod +x 02-CaminodelaserpienteOS.sh
    chmod +x 03-CaminodelaserpienteOS.sh
    chmod +x 04-CaminodelaserpienteOS.sh
    time ./01-CaminodelaserpienteOS.sh

    ssh -v user@localhost -p 2222
    scp -P 2222 -r /home/$USER/CaminodelaserpienteOS/ user@localhost:~/ #[1.]

---

<a y="[1.]"></a>
1. [https://www.debian.org/distrib/ | https://www.debian.org/doc/manuals/debian-reference/ch03.en.html#_systemd_init | debian-live-13.4.0-amd64-kde.iso](https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-13.4.0-amd64-kde.iso)
