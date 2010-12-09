timestamp=`date +%y%m%d`
fulltime=`date "+%Y/%m/%d-%H:%M:%S"`

rm -rf iup iup-cvs-$timestamp.tar.gz
cvs -d:pserver:anonymous:@iup.cvs.sourceforge.net:/cvsroot/iup login
cvs -z3 -d:pserver:anonymous@iup.cvs.sourceforge.net:/cvsroot/iup export -DNow iup
tar czf iup-cvs-$timestamp.tar.gz --owner=0 --group=0 iup

rm -rf cd cd-cvs-$timestamp.tar.gz
cvs -d:pserver:anonymous:@canvasdraw.cvs.sourceforge.net:/cvsroot/canvasdraw login
cvs -z3 -d:pserver:anonymous@canvasdraw.cvs.sourceforge.net:/cvsroot/canvasdraw export -DNow cd
tar czf cd-cvs-$timestamp.tar.gz --owner=0 --group=0 cd

rm -rf im im-cvs-$timestamp.tar.gz
cvs -d:pserver:anonymous:@imtoolkit.cvs.sourceforge.net:/cvsroot/imtoolkit login
cvs -z3 -d:pserver:anonymous@imtoolkit.cvs.sourceforge.net:/cvsroot/imtoolkit export -DNow im
tar czf im-cvs-$timestamp.tar.gz --owner=0 --group=0 im

rm -rf iup cd im

echo "### Build.PL fragment:"
echo "  warn \"###sources exported from CVS at $fulltime\n\";";
echo "  warn \"###\n\";";
echo "  \$builder->notes('iup_url',  'http://strawberryperl.com/package/kmx/testing/iup-cvs-$timestamp.tar.gz');"
echo "  \$builder->notes('iup_sha1', '`sha1sum iup-cvs-$timestamp.tar.gz | sed 's/ .*//'`');"
echo "  \$builder->notes('im_url',   'http://strawberryperl.com/package/kmx/testing/im-cvs-$timestamp.tar.gz');"
echo "  \$builder->notes('im_sha1',  '`sha1sum im-cvs-$timestamp.tar.gz | sed 's/ .*//'`');"
echo "  \$builder->notes('cd_url',   'http://strawberryperl.com/package/kmx/testing/cd-cvs-$timestamp.tar.gz');"
echo "  \$builder->notes('cd_sha1',  '`sha1sum cd-cvs-$timestamp.tar.gz | sed 's/ .*//'`');"
