#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <ctype.h>

#include "levenshtein.c"

#define CALCULATE_CHAR_LENGTHS(src, dst, srcb, dstb, srcc, dstc) \
      if(DO_UTF8(src) || DO_UTF8(dst)) { \
         srcc = sv_len_utf8(src); \
         dstc = sv_len_utf8(dst); \
      } else { \
         srcc = srcb; \
         dstc = dstb; \
      }

MODULE = Text::Levenshtein::Flexible		PACKAGE = Text::Levenshtein::Flexible		

unsigned int
levenshtein(src, dst)
	SV * src
	SV * dst
   INIT:
      STRLEN src_bytes, src_chars, dst_bytes, dst_chars;
      const char *src_c, *dst_c;
   CODE:
      src_c = SvPV(src, src_bytes);
      dst_c = SvPV(dst, dst_bytes);
      CALCULATE_CHAR_LENGTHS(src, dst, src_bytes, dst_bytes, src_chars, dst_chars);
	   RETVAL = levenshtein_internal(
         src_c, dst_c, src_bytes, dst_bytes, src_chars, dst_chars,
         1, 1, 1
      );
   OUTPUT:
      RETVAL

unsigned int
levenshtein_costs(src, dst, cost_ins, cost_del, cost_sub)
	SV * src
	SV * dst
   SV * cost_ins
   SV * cost_del
   SV * cost_sub
   INIT:
      STRLEN src_bytes, src_chars, dst_bytes, dst_chars;
      const char *src_c, *dst_c;
   CODE:
      src_c = SvPV(src, src_bytes);
      dst_c = SvPV(dst, dst_bytes);
      CALCULATE_CHAR_LENGTHS(src, dst, src_bytes, dst_bytes, src_chars, dst_chars);
	   RETVAL = levenshtein_internal(
         src_c, dst_c, src_bytes, dst_bytes, src_chars, dst_chars,
         SvUV(cost_ins), SvUV(cost_del), SvUV(cost_sub)
      );
   OUTPUT:
      RETVAL

unsigned int
levenshtein_le(src, dst, max)
	SV * src
	SV * dst
   SV * max
   INIT:
      STRLEN src_bytes, src_chars, dst_bytes, dst_chars;
      const char *src_c, *dst_c;
      const unsigned int max_dist = SvUV(max);
      unsigned int result;
   CODE:
      src_c = SvPV(src, src_bytes);
      dst_c = SvPV(dst, dst_bytes);
      CALCULATE_CHAR_LENGTHS(src, dst, src_bytes, dst_bytes, src_chars, dst_chars);
	   RETVAL = levenshtein_less_equal_internal(
         src_c, dst_c, src_bytes, dst_bytes, src_chars, dst_chars,
         1, 1, 1,
         max_dist
      );
      if(max_dist + 1 == RETVAL)   // exceeded max
         XSRETURN_UNDEF;
  OUTPUT:
      RETVAL

