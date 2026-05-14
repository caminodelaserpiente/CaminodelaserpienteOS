#! /bin/bash
#GPLv2 Last Dragon www.lastdragon.net Twitter @LastDragonMX


#configuracion
workdir=/securefile

echo "Creando la base de datos temporal para comparar firmas..."
echo ""
find /usr -type f -exec md5sum {} \; > /$workdir/usr.tmp
find /boot -type f -exec md5sum {} \; > /$workdir/boot.tmp
find /opt -type f -exec md5sum {} \; > /$workdir/opt.tmp
find /etc -type f -exec md5sum {} \; > /$workdir/etc.tmp
find /var -type f -not -path "/var/spool/*" -not -path "/var/log/*" -not -path "/var/tmp/*" -exec md5sum {} \; > /$workdir/var.tmp

echo ""
echo "Mostrando las diferencias..."
echo ""

diff $workdir/usr.txt $workdir/usr.tmp
diff $workdir/boot.txt $workdir/boot.tmp
diff $workdir/opt.txt $workdir/opt.tmp
diff $workdir/etc.txt $workdir/etc.tmp 
diff $workdir/var.txt $workdir/var.tmp

echo ""
echo "Limpiando archivos de comparacion..."
rm -f $workdir/usr.tmp $workdir/boot.tmp $workdir/opt.tmp $workdir/etc.tmp $workdir/var.tmp

echo ""
echo "Fin..."
