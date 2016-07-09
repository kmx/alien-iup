PROJNAME = im
LIBNAME = im_lzo
OPT = YES

DEF_FILE = im_lzo.def

SRCLZO = \
    minilzo.c
SRCLZO  := $(addprefix minilzo/, $(SRCLZO))
INCLUDES += minilzo

SRC := im_lzo.c $(SRCLZO)

USE_IM = Yes
IM = ..
    
ifneq ($(findstring MacOS, $(TEC_UNAME)), )
  ifneq ($(TEC_SYSMINOR), 4)
    BUILD_DYLIB=Yes
  endif
endif
