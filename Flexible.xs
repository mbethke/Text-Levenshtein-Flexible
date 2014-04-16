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
#define SETUP_SRC_DST \
      src_c = SvPV(src, src_bytes); \
      dst_c = SvPV(dst, dst_bytes);
#define CHECK_RETVAL_MAX if(max_dist + 1 <= RETVAL) XSRETURN_UNDEF;

struct tlf_object {
   unsigned int cost_ins, cost_del, cost_sub, max;
};
typedef struct tlf_object tlf_object_t;

typedef tlf_object_t * Text__Levenshtein__Flexible;

MODULE = Text::Levenshtein::Flexible		PACKAGE = Text::Levenshtein::Flexible		

PROTOTYPES: ENABLE

unsigned int
levenshtein(src, dst)
	SV * src
	SV * dst
   INIT:
      STRLEN src_bytes, src_chars, dst_bytes, dst_chars;
      const char *src_c, *dst_c;
   CODE:
      SETUP_SRC_DST;
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
      SETUP_SRC_DST;
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
      SETUP_SRC_DST;
      CALCULATE_CHAR_LENGTHS(src, dst, src_bytes, dst_bytes, src_chars, dst_chars);
	   RETVAL = levenshtein_less_equal_internal(
         src_c, dst_c, src_bytes, dst_bytes, src_chars, dst_chars,
         1, 1, 1,
         max_dist
      );
      CHECK_RETVAL_MAX;
  OUTPUT:
      RETVAL

unsigned int
levenshtein_le_costs(src, dst, max, cost_ins, cost_del, cost_sub)
	SV * src
	SV * dst
   SV * max
   SV * cost_ins
   SV * cost_del
   SV * cost_sub
   INIT:
      STRLEN src_bytes, src_chars, dst_bytes, dst_chars;
      const char *src_c, *dst_c;
      const unsigned int max_dist = SvUV(max);
      unsigned int result;
   CODE:
      SETUP_SRC_DST;
      CALCULATE_CHAR_LENGTHS(src, dst, src_bytes, dst_bytes, src_chars, dst_chars);
	   RETVAL = levenshtein_less_equal_internal(
         src_c, dst_c, src_bytes, dst_bytes, src_chars, dst_chars,
         SvUV(cost_ins), SvUV(cost_del), SvUV(cost_sub),
         max_dist
      );
      CHECK_RETVAL_MAX;
   OUTPUT:
      RETVAL

Text::Levenshtein::Flexible
new(class, max, cost_ins, cost_del, cost_sub)
   char * class
   SV * max
   SV * cost_ins
   SV * cost_del
   SV * cost_sub
   CODE:
      RETVAL = calloc(1, sizeof(tlf_object_t));
      if(!RETVAL) croak("no memory for %s", class);
      RETVAL->max = SvUV(max);
      RETVAL->cost_ins = SvUV(cost_ins);
      RETVAL->cost_del = SvUV(cost_del);
      RETVAL->cost_sub = SvUV(cost_sub);
   OUTPUT:
      RETVAL

void
DESTROY(self)
   Text::Levenshtein::Flexible self;
   CODE:
      if(self) free(self);

