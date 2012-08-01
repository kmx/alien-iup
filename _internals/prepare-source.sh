rm -rf cd im iup cd.orig im.orig iup.orig
rm -rf build-dllw4.log

tar xzf cd-5.5.1_Sources.tar.gz
tar xzf im-3.8_Sources.tar.gz
tar xzf iup-3.6_Sources.tar.gz 

cp -R cd cd.orig
cp -R im im.orig
cp -R iup iup.orig

(cd im; patch -i ../im.diff -p1)
(cd cd; patch -i ../cd.diff -p1)
(cd iup; patch -i ../iup.diff -p1)