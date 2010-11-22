#uncomment to clean
#mytarget=clean

echo "Starting static build"
rm -rf build-static.log
tecuname=gcc4

(
	cd cd/src
	echo curdir=`pwd`
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=cd_freetype $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=cd_ftgl $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=config $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=cd_pdflib $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=cdpdf $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=cdgl $mytarget
	#make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=cdcontextplus
) >> build-static.log 2>&1

(
	cd im/src
	echo curdir=`pwd`
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=config $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=im_process $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=im_jp2 $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=im_fftw $mytarget
) >> build-static.log 2>&1

(
	cd iup
	echo curdir=`pwd`
	(cd src;         make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srccd;       make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srccontrols; make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srcpplot;    make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srcgl;       make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srcim;       make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srcimglib;   make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srcole;      make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srctuio;     make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	#(cd srcweb;      make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
) >> build-static.log 2>&1

echo "Starting dynamic build"
rm -rf build-dynamic.log
tecuname=dllg4

(
	cd cd/src
	echo curdir=`pwd`
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=cd_freetype $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=cd_ftgl $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=cd_pdflib $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=cdpdf $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=cdgl $mytarget
	#make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=cdcontextplus $mytarget
) >> build-dynamic.log 2>&1

(
	cd im/src
	echo curdir=`pwd`
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=im_process $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=im_jp2 $mytarget
	make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes MF=im_fftw $mytarget
) >> build-dynamic.log 2>&1

(
	cd iup
	echo curdir=`pwd`
	(cd src;         make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srccd;       make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srccontrols; make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srcpplot;    make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srcgl;       make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srcim;       make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srcimglib;   make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srcole;      make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	(cd srctuio;     make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
	#(cd srcweb;      make -f ../tecmakewin.mak TEC_UNAME=$tecuname NO_DEPEND=Yes $mytarget)
) >> build-dynamic.log 2>&1

echo "Done!"