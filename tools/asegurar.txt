#! /bin/bash
#GPLv2 Last Dragon www.lastdragon.net Twitter @LastDragonMX

#configuracion
workdir=/securefile

echo "Creando la base de datos de firmas"
echo ""
find /usr -type f -exec md5sum {} \; > /$workdir/usr.txt
find /boot -type f -exec md5sum {} \; > /$workdir/boot.txt
find /opt -type f -exec md5sum {} \; > /$workdir/opt.txt
find /etc -type f -exec md5sum {} \; > /$workdir/etc.txt
find /var -type f -not -path "/var/spool/*" -not -path "/var/log/*" -not -path "/var/tmp/*" -exec md5sum {} \; > /$workdir/var.txt

echo ""
echo "Fin..."
