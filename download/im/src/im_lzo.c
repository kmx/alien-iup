/** \file
 * \brief Data Compression Utilities
 *
 * See Copyright Notice in im_lib.h
 */


#include <math.h>

#include "im_util.h"


#include "minilzo.h"

/* Work-memory needed for compression. Allocate memory in units
* of 'lzo_align_t' (instead of 'char') to make sure it is properly aligned.
*/

#define HEAP_ALLOC(var,size) \
    lzo_align_t __LZO_MMODEL var [ ((size) + (sizeof(lzo_align_t) - 1)) / sizeof(lzo_align_t) ]

static HEAP_ALLOC(wrkmem, LZO1X_1_MEM_COMPRESS);

int imCompressDataLZO(const void* src_data, int src_size, void* dst_data, int dst_size)
{
  lzo_uint dst_len = dst_size;

  int ret = lzo_init();
  if (ret != LZO_E_OK)
    return 0;

  ret = lzo1x_1_compress((const lzo_bytep)src_data, src_size, (lzo_bytep)dst_data, &dst_len, wrkmem);
  if (ret != LZO_E_OK)
    return 0;

  return (int)dst_len;
}

int imCompressDataUnLZO(const void* src_data, int src_size, void* dst_data, int dst_size)
{
  lzo_uint dst_len = dst_size;

  int ret = lzo_init();
  if (ret != LZO_E_OK)
    return 0;

  ret = lzo1x_decompress((const lzo_bytep)src_data, src_size, (lzo_bytep)dst_data, &dst_len, wrkmem);
  if (ret != LZO_E_OK)
    return 0;

  return (int)dst_len;
}
