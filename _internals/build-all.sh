#uncomment to clean
mytarget=$1

function do_job {
    tecnick=$1
    tecparams=$2
    echo "Starting build: '$tecnick' params: '$tecparams'"
    rm -rf build-$1.log

    echo "Building 'cd' ..."
    (    
        cd cd/src
        echo curdir=`pwd`
        make -f ../tecmakewin.mak $tecparams MF=cd_zlib $mytarget
        make -f ../tecmakewin.mak $tecparams MF=cd_freetype $mytarget
        make -f ../tecmakewin.mak $tecparams MF=cd_ftgl $mytarget
        make -f ../tecmakewin.mak $tecparams MF=config $mytarget
        make -f ../tecmakewin.mak $tecparams MF=cd_pdflib $mytarget
        make -f ../tecmakewin.mak $tecparams MF=cdpdf $mytarget
        make -f ../tecmakewin.mak $tecparams MF=cdgl $mytarget
        make -f ../tecmakewin.mak $tecparams MF=cdcontextplus $mytarget
    ) 2>&1 | tee -a build-$1.log

    echo "Building 'im' ..."
    (
        cd im/src
        echo curdir=`pwd`
        make -f ../tecmakewin.mak $tecparams MF=im_zlib $mytarget
        make -f ../tecmakewin.mak $tecparams MF=config $mytarget
        make -f ../tecmakewin.mak $tecparams MF=im_process $mytarget
#        make -f ../tecmakewin.mak $tecparams MF=im_process_omp $mytarget
#        make -f ../tecmakewin.mak $tecparams MF=im_capture $mytarget
        make -f ../tecmakewin.mak $tecparams MF=im_jp2 $mytarget
        make -f ../tecmakewin.mak $tecparams MF=im_fftw $mytarget
    ) 2>&1 | tee -a build-$1.log 2>&1

    echo "Building 'iup' ..."
    (
        cd iup
        echo curdir=`pwd`
        (cd src;           make -f ../tecmakewin.mak $tecparams $mytarget)
        (cd srccd;         make -f ../tecmakewin.mak $tecparams $mytarget)
        (cd srccontrols;   make -f ../tecmakewin.mak $tecparams $mytarget)
        (cd srcpplot;      make -f ../tecmakewin.mak $tecparams $mytarget)
        (cd srcmglplot;    make -f ../tecmakewin.mak $tecparams $mytarget)
        (cd srcscintilla;  make -f ../tecmakewin.mak $tecparams $mytarget)
        (cd srcgl;         make -f ../tecmakewin.mak $tecparams $mytarget)
        (cd srcglcontrols; make -f ../tecmakewin.mak $tecparams $mytarget)
        (cd srcim;         make -f ../tecmakewin.mak $tecparams $mytarget)
        (cd srcole;        make -f ../tecmakewin.mak $tecparams $mytarget)
#        (cd srcweb;        make -f ../tecmakewin.mak $tecparams $mytarget)
        (cd srctuio;       make -f ../tecmakewin.mak $tecparams $mytarget)
        (cd srcimglib;     make -f ../tecmakewin.mak $tecparams $mytarget)
    ) 2>&1 | tee -a build-$1.log 2>&1

    echo "Job '$1' done!"
}

#do_job mingw4    "NO_DEPEND=Yes TEC_UNAME=mingw4 MINGW4=z:/mingw32bit"
do_job dllw4    "NO_DEPEND=Yes TEC_UNAME=dllw4 MINGW4=z:/mingw32bit"
#do_job mingw4_64 "NO_DEPEND=Yes TEC_UNAME=mingw4_64 MINGW4=z:/mingw32bit"
#do_job gcc4      "NO_DEPEND=Yes TEC_UNAME=gcc4"
#do_job dllg4     "NO_DEPEND=Yes TEC_UNAME=dllg4"

export Include='Z:\vc6sp6\PlatformSDK\Include;Z:\vc6sp6\Bin\ATL\INCLUDE;Z:\vc6sp6\INCLUDE;Z:\vc6sp6\MFC\INCLUDE'
export Lib='Z:\vc6sp6\PlatformSDK\Lib;Z:\vc6sp6\LIB;Z:\vc6sp6\MFC\LIB'
#do_job vc6       "NO_DEPEND=Yes TEC_UNAME=vc6 VC6=z:/vc6sp6 PLATSDK=z:/vc6sp6/PlatformSDK"

export Include='Z:\SDK-WinSrv-2003sp1\Include;Z:\SDK-WinSrv-2003sp1\Include\crt;Z:\SDK-WinSrv-2003sp1\Include\crt\sys;Z:\SDK-WinSrv-2003sp1\Include\mfc;Z:\SDK-WinSrv-2003sp1\Include\atl'
export Lib='Z:\SDK-WinSrv-2003sp1\Lib\AMD64;Z:\SDK-WinSrv-2003sp1\Lib\AMD64\atlmfc'
#do_job vc8_64    "NO_DEPEND=Yes TEC_UNAME=vc8_64 VC8=z:/SDK-WinSrv-2003sp1 PLATSDK=z:/SDK-WinSrv-2003sp1 BIN=z:/SDK-WinSrv-2003sp1/bin/win64"
