
/* Define to 1 if translation of program messages to the user's native
   language is requested. */
/* #undef ENABLE_NLS */

/* The gettext domain we're using */
#define GETTEXT_PACKAGE "libexif-9"

#ifdef WIN32
#define exif_snprintf _snprintf
#else
#define exif_snprintf snprintf
#endif
