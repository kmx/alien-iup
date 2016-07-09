PROJNAME = im
LIBNAME = im_capture
OPT = YES
             
INCLUDES = ../include

# New Direct X does not includes Direct Show
# Direct Show is included in latest Platform SDK, but depends on Direct X...
DXSDK = d:/lng/dxsdk
WINSDK = d:/lng/winsdk

ifeq ($(TEC_UNAME), vc6)  
  #Use old Direct X with Direct Show
  #But do NOT use the VC6 strmiids.lib
  PLATSDK = d:/lng/vc7/PlatformSDK
endif

ifeq ($(TEC_UNAME), dll)  
  #Use old Direct X with Direct Show
  PLATSDK = d:/lng/vc7/PlatformSDK
  LDIR = ../lib/$(TEC_UNAME)
endif
  
ifeq ($(TEC_UNAME), vc8)
  INCLUDES += $(WINSDK)/include
  LDIR = $(WINSDK)/lib
endif

ifeq ($(TEC_UNAME), dll8)  
  INCLUDES += $(WINSDK)/include
  LDIR = $(WINSDK)/lib
endif
  
ifeq ($(TEC_UNAME), vc8_64)
  INCLUDES += $(WINSDK)/include
  LDIR = $(WINSDK)/lib/amd64
endif

ifeq ($(TEC_UNAME), dll8_64)  
  INCLUDES += $(WINSDK)/include
  LDIR = $(WINSDK)/lib/amd64
endif
  
ifneq ($(findstring vc10, $(TEC_UNAME)), )
  INCLUDES += $(WINSDK)/include
endif
ifneq ($(findstring dll10, $(TEC_UNAME)), )
  INCLUDES += $(WINSDK)/include
endif

ifneq ($(findstring vc11, $(TEC_UNAME)), )
  INCLUDES += $(WINSDK)/include
endif
ifneq ($(findstring dll11, $(TEC_UNAME)), )
  INCLUDES += $(WINSDK)/include
endif

ifneq ($(findstring vc12, $(TEC_UNAME)), )
  INCLUDES += $(WINSDK)/include
endif
ifneq ($(findstring dll12, $(TEC_UNAME)), )
  INCLUDES += $(WINSDK)/include
endif
ifneq ($(findstring vc14, $(TEC_UNAME)), )
  INCLUDES += $(WINSDK)/include
endif
ifneq ($(findstring dll14, $(TEC_UNAME)), )
  INCLUDES += $(WINSDK)/include
endif

ifneq ($(findstring Win, $(TEC_SYSNAME)), )
  INCLUDES += $(DXSDK)/include
  SRC = im_capture_dx.cpp
endif

#ifneq ($(findstring Linux, $(TEC_UNAME)), )
#  SRC = im_capture_v4l.cpp
#endif
             
LIBS = strmiids

#mingw3-dll:                    
#	@echo Importing MingW stub library
#	@cd ../lib/dll
#	@dlltool -d im_capture.def -D im_capture.dll -l ../lib/mingw3/libim_capture.a
#	@cd ../src

#VC6 DLL must be available
mingw4-dll:                    
	@echo Importing MingW stub library
	@cd ../lib/dll
	@dlltool -d im_capture.def -D im_capture.dll -l ../lib/mingw4/libim_capture.a
	@cd ../src
	@cp -f ../lib/dll/im_capture.dll ../lib/mingw4/

#VC6 DLL must be available
dllw4-dll:                    
	@echo Importing MingW stub library
	@cd ../lib/dll
	@dlltool -d im_capture.def -D im_capture.dll -l ../lib/dllw4/libim_capture.a
	@cd ../src
	@cp -f ../lib/dll/im_capture.dll ../lib/dllw4/

#bc56-dll:                    
#	@echo Importing Bcc stub library
#	@d:/lng/cbuilderx/bin/implib -a ../lib/bc56/im_capture.lib ../lib/dll/im_capture.dll

#owc1-dll:                    
#	@wlib -b -c -n -q -fo -io ../lib/owc1/im_capture.lib @im_capture.wlib
# TEST	@wlib -b -c -n -q -fo -io ../lib/owc1/im_capture.lib +../lib/dll/im_capture.dll


ifneq ($(findstring gcc, $(TEC_UNAME)), )
  $(error No support for DirectX in Cygwin)
endif
#ifneq ($(findstring mingw, $(TEC_UNAME)), )
#  $(error No support for DirectX in MingW)
#endif
ifneq ($(findstring cygw, $(TEC_UNAME)), )
  $(error No support for DirectX in Cygwin)
endif
#ifneq ($(findstring dllw, $(TEC_UNAME)), )
#  $(error No support for DirectX in MingW)
#endif
ifneq ($(findstring dllg, $(TEC_UNAME)), )
  $(error No support for DirectX in Cygwin)
endif
ifneq ($(findstring owc, $(TEC_UNAME)), )
  $(error No support for DirectX in OpenWatcom)
endif
ifneq ($(findstring bc, $(TEC_UNAME)), )
  $(error No support for DirectX in BorlandC)
endif
