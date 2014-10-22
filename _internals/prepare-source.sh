rm -rf cd im iup cd.orig im.orig iup.orig
rm -rf build-dllw4.log

tar -xzf ../IUP.Download/cd-5.8_Sources.tar.gz
tar -xzf ../IUP.Download/im-3.9_Sources.tar.gz
tar -xzf ../IUP.Download/iup-3.11.2_Sources.tar.gz

cp -R cd cd.orig
cp -R im im.orig
cp -R iup iup.orig

#(cd im; patch -i ../im.diff -p1)
#(cd cd; patch -i ../cd.diff -p1)
#(cd iup; patch -i ../iup.diff -p1)