diff -ru --strip-trailing-cr im.orig im | grep -v \^Only  > _im.diff
diff -ru --strip-trailing-cr cd.orig cd | grep -v \^Only > _cd.diff
diff -ru --strip-trailing-cr iup.orig iup | grep -v \^Only > _iup.diff

#diff -ru im.orig im | grep -v \^Only | sed "s,[\r\n],\n,g" > _imxx.diff
#diff -ru cd.orig cd | grep -v \^Only | sed "s,[\r\n],\n,g" > _cdxx.diff
#diff -ru iup.orig iup | grep -v \^Only | sed "s,[\r\n],\n,g" > _iupxx.diff

#diff -ru im.orig im | grep -v \^Only  > _imyy.diff
#diff -ru cd.orig cd | grep -v \^Only > _cdyy.diff
#diff -ru iup.orig iup | grep -v \^Only > _iupyy.diff
