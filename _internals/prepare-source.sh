rm -rf cd im iup cd.orig im.orig iup.orig

tar xzf cd-5.4.1_Sources.tar.gz
tar xzf im-3.6.3_Sources.tar.gz
tar xzf iup-3.3_Sources.tar.gz 

mv cd cd.orig
mv im im.orig
mv iup iup.orig

tar xzf cd-5.4.1_Sources.tar.gz
tar xzf im-3.6.3_Sources.tar.gz
tar xzf iup-3.3_Sources.tar.gz 

(cd im; patch -i ../im.diff -p1)
(cd cd; patch -i ../cd.diff -p1)
(cd iup; patch -i ../iup.diff -p1)