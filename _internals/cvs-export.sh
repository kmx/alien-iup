timestamp=`date +%y%m%d`

rm -rf iup cvzf iup-cvs-$timestamp.tar.gz
cvs -d:pserver:anonymous:@iup.cvs.sourceforge.net:/cvsroot/iup login
cvs -z3 -d:pserver:anonymous@iup.cvs.sourceforge.net:/cvsroot/iup export -DNow iup
tar czf iup-cvs-$timestamp.tar.gz --owner=0 --group=0 iup

rm -rf cd cvzf cd-cvs-$timestamp.tar.gz
cvs -d:pserver:anonymous@canvasdraw.cvs.sourceforge.net:/cvsroot/canvasdraw login
cvs -z3 -d:pserver:anonymous@canvasdraw.cvs.sourceforge.net:/cvsroot/canvasdraw export -DNow cd
tar czf cd-cvs-$timestamp.tar.gz --owner=0 --group=0 cd

rm -rf cd cvzf im-cvs-$timestamp.tar.gz
cvs -d:pserver:anonymous@imtoolkit.cvs.sourceforge.net:/cvsroot/imtoolkit login
cvs -z3 -d:pserver:anonymous@imtoolkit.cvs.sourceforge.net:/cvsroot/imtoolkit export -DNow im
tar czf im-cvs-$timestamp.tar.gz --owner=0 --group=0 im

rm -rf iup cd im

sha1sum *-$timestamp.tar.gz
