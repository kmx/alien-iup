/** \file
 * \brief Image Data Type Conversion
 *
 * See Copyright Notice in im_lib.h
 */

#include "im.h"
#include "im_util.h"
#include "im_complex.h"
#include "im_image.h"
#include "im_convert.h"
#include "im_color.h"
#include "im_attrib.h"
#ifdef IM_PROCESS
#include "process/im_process_counter.h"
#include "im_process_pnt.h"
#else
#include "im_counter.h"
#endif

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <memory.h>

#ifndef IM_PROCESS
#define IM_INT_PROCESSING     int processing = IM_ERR_NONE;
#define IM_BEGIN_PROCESSING   
#define IM_COUNT_PROCESSING   if (!imCounterInc(counter)) { processing = IM_ERR_COUNTER; break; }
#define IM_END_PROCESSING
#endif

/* NOTICE: we use the following nomenclature
   "Int" - imbyte, short, imushort, int
   "Real" - float, double
   "Cpx" - imcfloat, imcdouble
*/

/* IMPORTANT: leave template functions not "static" 
   because of some weird compiler bizarre errors. 
   Report on AIX C++.
*/
#ifdef AIX
#define IM_STATIC 
#else
#define IM_STATIC static
#endif

/* if gamma is applied then factor contains two conversions
   one for applying gamma,
   and other for conversion to dst_type_min-dst_type_max range.
   because gamma(0) = 0
     For EXP: gamma(x) = (e^(g*x))-1       
     For LOG: gamma(x) = log((g*x)+1)      
   because gamma(1) = 1
     gfactor = exp(g)-1
     gfactor = log(g+1)
*/

template <class T>
inline T iGammaFactor(T range, float gamma)
{
  if (gamma == 0)
    return range;
  else if (gamma < 0)
    return range/log(1 - T(gamma));
  else
    return range/(exp(T(gamma)) - 1);
}

template <class T>
inline T iGammaFunc(T factor, T min, float gamma, T value)
{
  // Here  0<value<1   (always)
  if (gamma != 0)
  {
    if (gamma < 0)
      value = log(1 - value*T(gamma));
    else
      value = exp(value*T(gamma)) - 1;
  }

  return factor*value + min;
}

template <class T> 
inline int iIsNegativeType(T tmp)
{
  tmp = (T)-1;
  if (tmp > 0)
    return 0;
  else
    return 1;
}

template <class T> 
inline int iDataType(T tmp)
{
  // Discover the data type from the template.
  // Used only for integers.
  int size_of = sizeof(T);
  int data_type = IM_BYTE;
  if (size_of == 8)
    data_type = IM_DOUBLE;
  else if (size_of == 4)
  {
    tmp = (T)0.1;
    if (tmp == 0)
      data_type = IM_INT;
    else
      data_type = IM_FLOAT;
  }
  else if (size_of == 2)
  {
    tmp = (T)-1;
    if (tmp > 0)
      data_type = IM_USHORT;
    else
      data_type = IM_SHORT;
  }
  return data_type;
}

template <class T> 
inline void iDataTypeIntMinMax(T& type_min, T& type_max, int absolute)
{
  int data_type = iDataType(type_max);
  type_max = (T)imColorMax(data_type);
  type_min = (T)imColorMin(data_type);
  if (absolute)
    type_min = 0;
}

template <class T, class TR> 
inline void iDataTypeRealMinMax(TR& min, TR& max, int absolute, T tmp)
{
  // Used only when converting real<=>int
  max = (TR)1.0;
  min = 0;

  if (!absolute)
  {
    if (iIsNegativeType(tmp))
    {
      min = (TR)-0.5;
      max = (TR)+0.5;
    }
  }
}


/**********************************************************************/


template <class SRCT, class DSTT> 
IM_STATIC int iCopyDirect(int count, const SRCT *src_map, DSTT *dst_map)
{
  // small range to big range, no need to scale, not crop
#ifdef _OPENMP
#pragma omp parallel for if (IM_OMP_MINCOUNT(count))
#endif
  for (int i = 0; i < count; i++)
  {
    dst_map[i] = (DSTT)(src_map[i]);
  }

  return IM_ERR_NONE;
}
  
template <class SRCT, class DSTT> 
IM_STATIC int iDemoteIntToIntDirect(int count, const SRCT *src_map, DSTT *dst_map, int absolute)
{
  // big integer to small integer, no need to scale, just need to crop
  DSTT dst_type_min, dst_type_max;
  iDataTypeIntMinMax(dst_type_min, dst_type_max, absolute);

#ifdef _OPENMP
#pragma omp parallel for if (IM_OMP_MINCOUNT(count))
#endif
  for (int i = 0; i < count; i++)
  {
    SRCT value;

    if (absolute)
      value = imAbs(src_map[i]);
    else
      value = src_map[i];

    if (value > dst_type_max)
      value = (SRCT)dst_type_max;

    if (value < dst_type_min)
      value = (SRCT)dst_type_min;

    dst_map[i] = (DSTT)(value);
  }

  return IM_ERR_NONE;
}

template <class SRCT, class DSTT> 
IM_STATIC int iPromoteIntToInt(int count, const SRCT *src_map, DSTT *dst_map, int absolute)
{
  // small integer to big integer, need to shift if necessary
  // also includes ushort <-> short conversion

  // If SRC can has negative values, but DST can't then must shift
  SRCT shift = 0;
  if (!absolute)
  {
    if (iIsNegativeType(*src_map) && !iIsNegativeType(*dst_map))
    {
      SRCT type_min, type_max;
      iDataTypeIntMinMax(type_min, type_max, absolute);
      shift = type_min;
    }
  }

#ifdef _OPENMP
#pragma omp parallel for if (IM_OMP_MINCOUNT(count))
#endif
  for (int i = 0; i < count; i++)
  {
    SRCT value;

    if (absolute)
      value = imAbs(src_map[i]);
    else
      value = src_map[i] - shift;

    dst_map[i] = (DSTT)(value);
  }

  return IM_ERR_NONE;
}

template <class SRCT, class DSTT> 
IM_STATIC int iDemoteIntToInt(int count, const SRCT *src_map, DSTT *dst_map, int absolute, int cast_mode, int counter, imAttribTable* attrib_table)
{
  // big integer to small integer, need to scale down
  SRCT min, max;
  DSTT dst_type_min, dst_type_max;

  if (cast_mode == IM_CAST_MINMAX)  // search for min-max
    imMinMaxType(src_map, count, min, max, absolute);
  else  
  {
    // IM_CAST_FIXED - use data type limits for min-max
    iDataTypeIntMinMax(min, max, absolute);

    if (cast_mode == IM_CAST_USER)  // get min,max from atributes
    {
      float* amin = (float*)attrib_table->Get("UserMin");
      if (amin) min = (SRCT)(*amin);
      float* amax = (float*)attrib_table->Get("UserMax");
      if (amax) max = (SRCT)(*amax);
    }
  }

  iDataTypeIntMinMax(dst_type_min, dst_type_max, absolute);

  int direct = 0; // must scale SRC to fit DST
  if (min >= dst_type_min && max <= dst_type_max)
    direct = 1; // no need for conversion

  float factor = ((float)dst_type_max - (float)dst_type_min + 1.0f) / ((float)max - (float)min + 1.0f);

  IM_INT_PROCESSING;

#ifdef _OPENMP
#pragma omp parallel for if (IM_OMP_MINCOUNT(count))
#endif
  for (int i = 0; i < count; i++)
  {
#ifdef _OPENMP
    #pragma omp flush (processing)
#endif
    IM_BEGIN_PROCESSING;

    SRCT value;
    if (absolute)
      value = imAbs(src_map[i]);
    else
      value = src_map[i];

    if (value >= max)
      dst_map[i] = dst_type_max;
    else if (value <= min)
      dst_map[i] = dst_type_min;
    else
    {
      if (direct)
        dst_map[i] = (DSTT)value;
      else
        dst_map[i] = (DSTT)imResampleInt(value - min, factor) + dst_type_min;
    }

    IM_COUNT_PROCESSING;
#ifdef _OPENMP
    #pragma omp flush (processing)
#endif
    IM_END_PROCESSING;
  }

  return processing;
}


/**********************************************************************/


template <class SRCT, class DSTT>
IM_STATIC int iPromoteIntToReal(int count, const SRCT *src_map, DSTT *dst_map, float gamma, int absolute, int cast_mode, int counter, imAttribTable* attrib_table)
{
  // integer to real, always have to scale to 0:1 or -0.5:+0.5
  SRCT min, max;
  DSTT dst_type_min, dst_type_max;

  if (cast_mode == IM_CAST_MINMAX)   // search for min-max
    imMinMaxType(src_map, count, min, max, absolute);
  else  
  {
    // IM_CAST_FIXED - use data type limits for min-max
    iDataTypeIntMinMax(min, max, absolute);

    if (cast_mode == IM_CAST_USER)  // get min,max from atributes
    {
      float* amin = (float*)attrib_table->Get("UserMin");
      if (amin) min = (SRCT)(*amin);
      float* amax = (float*)attrib_table->Get("UserMax");
      if (amax) max = (SRCT)(*amax);
    }
  }

  iDataTypeRealMinMax(dst_type_min, dst_type_max, absolute, *src_map);

  DSTT dst_type_range = 1.0f;
  DSTT range = DSTT(max - min + 1);

  gamma = -gamma; // gamma is inverted here, because we are promoting int2real
  DSTT factor = iGammaFactor(dst_type_range, gamma);

  IM_INT_PROCESSING;

#ifdef _OPENMP
#pragma omp parallel for if (IM_OMP_MINCOUNT(count))
#endif
  for (int i = 0; i < count; i++)
  {
#ifdef _OPENMP
    #pragma omp flush (processing)
#endif
    IM_BEGIN_PROCESSING;

    DSTT fvalue;
    if (absolute)
      fvalue = (imAbs(src_map[i]) - min + DSTT(0.5)) / range;
    else
      fvalue = (src_map[i] - min + DSTT(0.5)) / range;

    // Now 0 <= fvalue <= 1 (if min-max are correct)

    if (fvalue >= 1)
      dst_map[i] = dst_type_max;
    else if (fvalue <= 0)
      dst_map[i] = dst_type_min;
    else
      dst_map[i] = iGammaFunc(factor, dst_type_min, gamma, fvalue);

    IM_COUNT_PROCESSING;
#ifdef _OPENMP
    #pragma omp flush (processing)
#endif
    IM_END_PROCESSING;
  }

  return processing;
}

template <class SRCT, class DSTT>
IM_STATIC int iDemoteRealToInt(int count, const SRCT *src_map, DSTT *dst_map, float gamma, int absolute, int cast_mode, int counter, imAttribTable* attrib_table)
{
  // real to integer, always have to scale from 0:1 or -0.5:+0.5
  SRCT min, max;
  DSTT dst_type_min, dst_type_max;

  if (cast_mode == IM_CAST_MINMAX)  // search for min-max
    imMinMaxType(src_map, count, min, max, absolute);
  else  
  {
    // IM_CAST_FIXED - use data type limits for min-max
    iDataTypeRealMinMax(min, max, absolute, *dst_map);

    if (cast_mode == IM_CAST_USER)  // get min,max from atributes
    {
      float* amin = (float*)attrib_table->Get("UserMin");
      if (amin) min = (SRCT)*amin;
      float* amax = (float*)attrib_table->Get("UserMax");
      if (amax) max = (SRCT)*amax;
    }
  }

  iDataTypeIntMinMax(dst_type_min, dst_type_max, absolute);

  int dst_type_range = dst_type_max - dst_type_min + 1;
  SRCT range = max - min;

  SRCT factor = iGammaFactor((SRCT)dst_type_range, gamma);

  IM_INT_PROCESSING;

#ifdef _OPENMP
#pragma omp parallel for if (IM_OMP_MINCOUNT(count))
#endif
  for (int i = 0; i < count; i++)
  {
#ifdef _OPENMP
    #pragma omp flush (processing)
#endif
    IM_BEGIN_PROCESSING;

    SRCT value;
    if (absolute)
      value = ((SRCT)imAbs(src_map[i]) - min) / range;
    else
      value = (src_map[i] - min)/range; 

    // Now 0 <= value <= 1 (if min-max are correct)

    if (value >= 1)
      dst_map[i] = dst_type_max;
    else if (value <= 0)
      dst_map[i] = dst_type_min;
    else
    {
      value = iGammaFunc(factor, (SRCT)dst_type_min, gamma, value);
      int ivalue = imRound(value);
      if (ivalue >= dst_type_max)
        dst_map[i] = dst_type_max;
      else if (ivalue <= dst_type_min)
        dst_map[i] = dst_type_min;
      else
        dst_map[i] = (DSTT)imRound(value - 0.5f);
    }

    IM_COUNT_PROCESSING;
#ifdef _OPENMP
    #pragma omp flush (processing)
#endif
    IM_END_PROCESSING;
  }

  return processing;
}


/**********************************************************************/

template <class SRCT, class DSTT>
static int iCopyCpxDirect(int count, const imComplex<SRCT>* src_map, imComplex<DSTT> *dst_map)
{
#ifdef _OPENMP
#pragma omp parallel for if (IM_OMP_MINCOUNT(count))
#endif
  for (int i = 0; i < count; i++)
  {
    dst_map[i].real = (DSTT)(src_map[i].real);
    dst_map[i].imag = (DSTT)(src_map[i].imag);
  }

  return IM_ERR_NONE;
}

template <class SRCT, class DSTT>
static int iDemoteCpxToReal(int count, const imComplex<SRCT>* src_map, DSTT *dst_map, int cpx2real)
{
  SRCT (*CpxCnv)(const imComplex<SRCT>& cpx) = NULL;

  switch(cpx2real)
  {
  case IM_CPX_REAL:  CpxCnv = cpxreal; break;
  case IM_CPX_IMAG:  CpxCnv = cpximag; break;
  case IM_CPX_MAG:   CpxCnv = cpxmag; break;
  case IM_CPX_PHASE: CpxCnv = cpxphase; break;
  }

#ifdef _OPENMP
#pragma omp parallel for if (IM_OMP_MINCOUNT(count))
#endif
  for (int i = 0; i < count; i++)
  {
    dst_map[i] = (DSTT)CpxCnv(src_map[i]);
  }

  return IM_ERR_NONE;
}
                                                                     
template <class SRCT, class DSTT>
IM_STATIC int iDemoteCpxToInt(int count, const imComplex<SRCT>* src_map, DSTT *dst_map, int cpx2real, float gamma, int absolute, int cast_mode, int counter, imAttribTable* attrib_table)
{
  SRCT* real_map = (SRCT*)malloc(count*sizeof(SRCT));
  if (!real_map) return IM_ERR_MEM;

  // complex to real
  iDemoteCpxToReal(count, src_map, real_map, cpx2real);

  // real to integer
  if (iDemoteRealToInt(count, real_map, dst_map, gamma, absolute, cast_mode, counter, attrib_table) != IM_ERR_NONE)
  {
    free(real_map);
    return IM_ERR_COUNTER;
  }

  free(real_map);
  return IM_ERR_NONE;
}

template <class SRCT, class DSTT>
IM_STATIC int iPromoteToCpxDirect(int count, const SRCT *src_map, imComplex<DSTT> *dst_map)
{
#ifdef _OPENMP
#pragma omp parallel for if (IM_OMP_MINCOUNT(count))
#endif
  for (int i = 0; i < count; i++)
  {
    dst_map[i].real = (DSTT)(src_map[i]);
  }

  return IM_ERR_NONE;
}

template <class SRCT, class DSTT> 
IM_STATIC int iPromoteIntToCpx(int count, const SRCT* src_map, imComplex<DSTT> *dst_map, float gamma, int absolute, int cast_mode, int counter, imAttribTable* attrib_table)
{
  DSTT* real_map = (DSTT*)malloc(count*sizeof(DSTT));
  if (!real_map) return IM_ERR_MEM;

  // integer to real
  if (iPromoteIntToReal(count, src_map, real_map, gamma, absolute, cast_mode, counter, attrib_table) != IM_ERR_NONE)
  {
    free(real_map);
    return IM_ERR_COUNTER;
  }

  // real to complex
  iPromoteToCpxDirect(count, real_map, dst_map);

  free(real_map);
  return IM_ERR_NONE;
}


/**********************************************************************/


#ifdef IM_PROCESS
int imProcessConvertDataType(const imImage* src_image, imImage* dst_image, int cpx2real, float gamma, int absolute, int cast_mode)
#else
int imConvertDataType(const imImage* src_image, imImage* dst_image, int cpx2real, float gamma, int absolute, int cast_mode)
#endif
{
  assert(src_image);
  assert(dst_image);

  if (!imImageMatchColorSpace(src_image, dst_image))
    return IM_ERR_DATA;

  if (src_image->data_type == dst_image->data_type)
    return IM_ERR_DATA;

  int total_count = src_image->depth * src_image->count;
  int ret = IM_ERR_DATA;
#ifdef IM_PROCESS
  int counter = imProcessCounterBegin("Convert Data Type");
#else
  int counter = imCounterBegin("Convert Data Type");
#endif
  char msg[50];
  sprintf(msg, "Converting to %s...", imDataTypeName(dst_image->data_type));
  imCounterTotal(counter, total_count, msg);

  imAttribTable* attrib_table = (imAttribTable*)(src_image->attrib_table);

  switch(src_image->data_type)
  {
  case IM_BYTE:
    switch(dst_image->data_type)
    {
    case IM_SHORT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iCopyDirect(total_count, (const imbyte*)src_image->data[0], (short*)dst_image->data[0]);
      else
        ret = iPromoteIntToInt(total_count, (const imbyte*)src_image->data[0], (short*)dst_image->data[0], absolute);
      break;
    case IM_USHORT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iCopyDirect(total_count, (const imbyte*)src_image->data[0], (imushort*)dst_image->data[0]);
      else
        ret = iPromoteIntToInt(total_count, (const imbyte*)src_image->data[0], (imushort*)dst_image->data[0], absolute);
      break;
    case IM_INT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iCopyDirect(total_count, (const imbyte*)src_image->data[0], (int*)dst_image->data[0]);
      else
        ret = iPromoteIntToInt(total_count, (const imbyte*)src_image->data[0], (int*)dst_image->data[0], absolute);
      break;
    case IM_FLOAT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iCopyDirect(total_count, (const imbyte*)src_image->data[0], (float*)dst_image->data[0]);
      else
        ret = iPromoteIntToReal(total_count, (const imbyte*)src_image->data[0], (float*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_CFLOAT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iPromoteToCpxDirect(total_count, (const imbyte*)src_image->data[0], (imcfloat*)dst_image->data[0]);
      else
        ret = iPromoteIntToCpx(total_count, (const imbyte*)src_image->data[0], (imcfloat*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_DOUBLE:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iCopyDirect(total_count, (const imbyte*)src_image->data[0], (double*)dst_image->data[0]);
      else
        ret = iPromoteIntToReal(total_count, (const imbyte*)src_image->data[0], (double*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_CDOUBLE:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iPromoteToCpxDirect(total_count, (const imbyte*)src_image->data[0], (imcdouble*)dst_image->data[0]);
      else
        ret = iPromoteIntToCpx(total_count, (const imbyte*)src_image->data[0], (imcdouble*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    }
    break;
  case IM_SHORT:
    switch(dst_image->data_type)
    {
    case IM_BYTE:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const short*)src_image->data[0], (imbyte*)dst_image->data[0], absolute);
      else
        ret = iDemoteIntToInt(total_count, (const short*)src_image->data[0], (imbyte*)dst_image->data[0], absolute, cast_mode, counter, attrib_table);
      break;
    case IM_USHORT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const short*)src_image->data[0], (imushort*)dst_image->data[0], absolute);
      else
        ret = iPromoteIntToInt(total_count, (const short*)src_image->data[0], (imushort*)dst_image->data[0], absolute);
      break;
    case IM_INT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iCopyDirect(total_count, (const short*)src_image->data[0], (int*)dst_image->data[0]);
      else
        ret = iPromoteIntToInt(total_count, (const short*)src_image->data[0], (int*)dst_image->data[0], absolute);
      break;
    case IM_FLOAT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iCopyDirect(total_count, (const short*)src_image->data[0], (float*)dst_image->data[0]);
      else
        ret = iPromoteIntToReal(total_count, (const short*)src_image->data[0], (float*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_CFLOAT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iPromoteToCpxDirect(total_count, (const short*)src_image->data[0], (imcfloat*)dst_image->data[0]);
      else
        ret = iPromoteIntToCpx(total_count, (const short*)src_image->data[0], (imcfloat*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_DOUBLE:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iCopyDirect(total_count, (const short*)src_image->data[0], (double*)dst_image->data[0]);
      else
        ret = iPromoteIntToReal(total_count, (const short*)src_image->data[0], (double*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_CDOUBLE:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iPromoteToCpxDirect(total_count, (const short*)src_image->data[0], (imcdouble*)dst_image->data[0]);
      else
        ret = iPromoteIntToCpx(total_count, (const short*)src_image->data[0], (imcdouble*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    }
    break;
  case IM_USHORT:
    switch(dst_image->data_type)
    {
    case IM_BYTE:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const imushort*)src_image->data[0], (imbyte*)dst_image->data[0], absolute);
      else
        ret = iDemoteIntToInt(total_count, (const imushort*)src_image->data[0], (imbyte*)dst_image->data[0], absolute, cast_mode, counter, attrib_table);
      break;
    case IM_SHORT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const imushort*)src_image->data[0], (short*)dst_image->data[0], absolute);
      else
        ret = iPromoteIntToInt(total_count, (const imushort*)src_image->data[0], (short*)dst_image->data[0], absolute);
      break;
    case IM_INT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iCopyDirect(total_count, (const imushort*)src_image->data[0], (int*)dst_image->data[0]);
      else
        ret = iPromoteIntToInt(total_count, (const imushort*)src_image->data[0], (int*)dst_image->data[0], absolute);
      break;
    case IM_FLOAT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iCopyDirect(total_count, (const imushort*)src_image->data[0], (float*)dst_image->data[0]);
      else
        ret = iPromoteIntToReal(total_count, (const imushort*)src_image->data[0], (float*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_CFLOAT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iPromoteToCpxDirect(total_count, (const imushort*)src_image->data[0], (imcfloat*)dst_image->data[0]);
      else
        ret = iPromoteIntToCpx(total_count, (const imushort*)src_image->data[0], (imcfloat*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_DOUBLE:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iCopyDirect(total_count, (const imushort*)src_image->data[0], (double*)dst_image->data[0]);
      else
        ret = iPromoteIntToReal(total_count, (const imushort*)src_image->data[0], (double*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_CDOUBLE:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iPromoteToCpxDirect(total_count, (const imushort*)src_image->data[0], (imcdouble*)dst_image->data[0]);
      else
        ret = iPromoteIntToCpx(total_count, (const imushort*)src_image->data[0], (imcdouble*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    }
    break;
  case IM_INT:
    switch(dst_image->data_type)
    {
    case IM_BYTE:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const int*)src_image->data[0], (imbyte*)dst_image->data[0], absolute);
      else
        ret = iDemoteIntToInt(total_count, (const int*)src_image->data[0], (imbyte*)dst_image->data[0], absolute, cast_mode, counter, attrib_table);
      break;
    case IM_SHORT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const int*)src_image->data[0], (short*)dst_image->data[0], absolute);
      else
        ret = iDemoteIntToInt(total_count, (const int*)src_image->data[0], (short*)dst_image->data[0], absolute, cast_mode, counter, attrib_table);
      break;
    case IM_USHORT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const int*)src_image->data[0], (imushort*)dst_image->data[0], absolute);
      else
        ret = iDemoteIntToInt(total_count, (const int*)src_image->data[0], (imushort*)dst_image->data[0], absolute, cast_mode, counter, attrib_table);
      break;
    case IM_FLOAT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iCopyDirect(total_count, (const int*)src_image->data[0], (float*)dst_image->data[0]);
      else
        ret = iPromoteIntToReal(total_count, (const int*)src_image->data[0], (float*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_CFLOAT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iPromoteToCpxDirect(total_count, (const int*)src_image->data[0], (imcfloat*)dst_image->data[0]);
      else
        ret = iPromoteIntToCpx(total_count, (const int*)src_image->data[0], (imcfloat*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_DOUBLE:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iCopyDirect(total_count, (const int*)src_image->data[0], (double*)dst_image->data[0]);
      else
        ret = iPromoteIntToReal(total_count, (const int*)src_image->data[0], (double*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_CDOUBLE:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iPromoteToCpxDirect(total_count, (const int*)src_image->data[0], (imcdouble*)dst_image->data[0]);
      else
        ret = iPromoteIntToCpx(total_count, (const int*)src_image->data[0], (imcdouble*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    }
    break;
  case IM_FLOAT:
    switch(dst_image->data_type)
    {
    case IM_BYTE:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const float*)src_image->data[0], (imbyte*)dst_image->data[0], absolute);
      else
        ret = iDemoteRealToInt(total_count, (const float*)src_image->data[0], (imbyte*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_SHORT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const float*)src_image->data[0], (short*)dst_image->data[0], absolute);
      else
        ret = iDemoteRealToInt(total_count, (const float*)src_image->data[0], (short*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_USHORT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const float*)src_image->data[0], (imushort*)dst_image->data[0], absolute);
      else
        ret = iDemoteRealToInt(total_count, (const float*)src_image->data[0], (imushort*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_INT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const float*)src_image->data[0], (int*)dst_image->data[0], absolute);
      else
        ret = iDemoteRealToInt(total_count, (const float*)src_image->data[0], (int*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_DOUBLE:
      ret = iCopyDirect(total_count, (const float*)src_image->data[0], (double*)dst_image->data[0]);
      break;
    case IM_CFLOAT:
      ret = iPromoteToCpxDirect(total_count, (const float*)src_image->data[0], (imcfloat*)dst_image->data[0]);
      break;
    case IM_CDOUBLE:
      ret = iPromoteToCpxDirect(total_count, (const float*)src_image->data[0], (imcdouble*)dst_image->data[0]);
      break;
    }
    break;
  case IM_DOUBLE:
    switch(dst_image->data_type)
    {
    case IM_BYTE:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const double*)src_image->data[0], (imbyte*)dst_image->data[0], absolute);
      else
        ret = iDemoteRealToInt(total_count, (const double*)src_image->data[0], (imbyte*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_SHORT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const double*)src_image->data[0], (short*)dst_image->data[0], absolute);
      else
        ret = iDemoteRealToInt(total_count, (const double*)src_image->data[0], (short*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_USHORT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const double*)src_image->data[0], (imushort*)dst_image->data[0], absolute);
      else
        ret = iDemoteRealToInt(total_count, (const double*)src_image->data[0], (imushort*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_INT:
      if (cast_mode == IM_CAST_DIRECT)
        ret = iDemoteIntToIntDirect(total_count, (const double*)src_image->data[0], (int*)dst_image->data[0], absolute);
      else
        ret = iDemoteRealToInt(total_count, (const double*)src_image->data[0], (int*)dst_image->data[0], gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_FLOAT:
      ret = iCopyDirect(total_count, (const double*)src_image->data[0], (float*)dst_image->data[0]);
      break;
    case IM_CFLOAT:
      ret = iPromoteToCpxDirect(total_count, (const double*)src_image->data[0], (imcfloat*)dst_image->data[0]);
      break;
    case IM_CDOUBLE:
      ret = iPromoteToCpxDirect(total_count, (const double*)src_image->data[0], (imcdouble*)dst_image->data[0]);
      break;
    }
    break;
  case IM_CFLOAT:
    switch(dst_image->data_type)                                                                       
    {
    case IM_BYTE:
      ret = iDemoteCpxToInt(total_count, (const imcfloat*)src_image->data[0], (imbyte*)dst_image->data[0], cpx2real, gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_SHORT:
      ret = iDemoteCpxToInt(total_count, (const imcfloat*)src_image->data[0], (short*)dst_image->data[0], cpx2real, gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_USHORT:
      ret = iDemoteCpxToInt(total_count, (const imcfloat*)src_image->data[0], (imushort*)dst_image->data[0], cpx2real, gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_INT:
      ret = iDemoteCpxToInt(total_count, (const imcfloat*)src_image->data[0], (int*)dst_image->data[0], cpx2real, gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_FLOAT:
      ret = iDemoteCpxToReal(total_count, (const imcfloat*)src_image->data[0], (float*)dst_image->data[0], cpx2real);
      break;
    case IM_DOUBLE:
      ret = iDemoteCpxToReal(total_count, (const imcfloat*)src_image->data[0], (double*)dst_image->data[0], cpx2real);
      break;
    case IM_CDOUBLE:
      ret = iCopyCpxDirect(total_count, (const imcfloat*)src_image->data[0], (imcdouble*)dst_image->data[0]);
      break;
    }
    break;
  case IM_CDOUBLE:
    switch (dst_image->data_type)
    {
    case IM_BYTE:
      ret = iDemoteCpxToInt(total_count, (const imcdouble*)src_image->data[0], (imbyte*)dst_image->data[0], cpx2real, gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_SHORT:
      ret = iDemoteCpxToInt(total_count, (const imcdouble*)src_image->data[0], (short*)dst_image->data[0], cpx2real, gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_USHORT:
      ret = iDemoteCpxToInt(total_count, (const imcdouble*)src_image->data[0], (imushort*)dst_image->data[0], cpx2real, gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_INT:
      ret = iDemoteCpxToInt(total_count, (const imcdouble*)src_image->data[0], (int*)dst_image->data[0], cpx2real, gamma, absolute, cast_mode, counter, attrib_table);
      break;
    case IM_FLOAT:
      ret = iDemoteCpxToReal(total_count, (const imcdouble*)src_image->data[0], (float*)dst_image->data[0], cpx2real);
      break;
    case IM_DOUBLE:
      ret = iDemoteCpxToReal(total_count, (const imcdouble*)src_image->data[0], (double*)dst_image->data[0], cpx2real);
      break;
    case IM_CFLOAT:
      ret = iCopyCpxDirect(total_count, (const imcdouble*)src_image->data[0], (imcfloat*)dst_image->data[0]);
      break;
    }
    break;
  }

#ifdef IM_PROCESS
  imProcessCounterEnd(counter);
#else
  imCounterEnd(counter);
#endif
  return ret;
}
