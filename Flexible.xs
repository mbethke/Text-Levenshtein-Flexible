#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <ctype.h>
#include <limits.h>

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
#define SETUP_S_CHAR_LEN(s_char_len, src_bytes, src_chars, dst_bytes, dst_chars) \
      if(src_bytes != src_chars || dst_bytes != dst_chars) \
         s_char_len = setup_charlen(src_c, src_chars);
#define CHECK_RETVAL_MAX(var) if(RETVAL > (var)) XSRETURN_UNDEF;

struct tlf_object {
   unsigned int cost_ins, cost_del, cost_sub, max;
};
typedef struct tlf_object tlf_object_t;

typedef tlf_object_t * Text__Levenshtein__Flexible;

MODULE = Text::Levenshtein::Flexible		PACKAGE = Text::Levenshtein::Flexible

PROTOTYPES: ENABLE

unsigned int
levenshtein_c(src, dst, cost_ins, cost_del, cost_sub)
	SV * src
	SV * dst
   SV * cost_ins
   SV * cost_del
   SV * cost_sub
   PROTOTYPE: $$$$$
   INIT:
      STRLEN src_bytes, src_chars, dst_bytes, dst_chars;
      const char *src_c, *dst_c;
      int *s_char_len = NULL;
   CODE:
      SETUP_SRC_DST;
      CALCULATE_CHAR_LENGTHS(src, dst, src_bytes, dst_bytes, src_chars, dst_chars);
      SETUP_S_CHAR_LEN(s_char_len, src_bytes, src_chars, dst_bytes, dst_chars)
	   RETVAL = levenshtein_internal(
         src_c, dst_c, s_char_len, src_bytes, dst_bytes, src_chars, dst_chars,
         SvUV(cost_ins), SvUV(cost_del), SvUV(cost_sub)
      );
   OUTPUT:
      RETVAL

unsigned int
levenshtein_lc(src, dst, max, cost_ins, cost_del, cost_sub)
	SV * src
	SV * dst
   SV * max
   SV * cost_ins
   SV * cost_del
   SV * cost_sub
   PROTOTYPE: $$$$$$
   INIT:
      STRLEN src_bytes, src_chars, dst_bytes, dst_chars;
      const char *src_c, *dst_c;
      int *s_char_len = NULL;
      const unsigned int max_dist = SvUV(max);
   CODE:
      SETUP_SRC_DST;
      CALCULATE_CHAR_LENGTHS(src, dst, src_bytes, dst_bytes, src_chars, dst_chars);
      SETUP_S_CHAR_LEN(s_char_len, src_bytes, src_chars, dst_bytes, dst_chars)
	   RETVAL = levenshtein_less_equal_internal(
         src_c, dst_c, s_char_len, src_bytes, dst_bytes, src_chars, dst_chars,
         SvUV(cost_ins), SvUV(cost_del), SvUV(cost_sub),
         max_dist
      );
      CHECK_RETVAL_MAX(max_dist);
   OUTPUT:
      RETVAL

Text::Levenshtein::Flexible
new(class, ...)
   char * class
   PROTOTYPE: DISABLE
   CODE:
      Newxz(RETVAL, 1, tlf_object_t);
      if(!RETVAL) croak("no memory for %s", class);
      RETVAL->max      = items > 1 ? SvUV(ST(1)) : UINT_MAX;
      RETVAL->cost_ins = items > 2 ? SvUV(ST(2)) : 1;
      RETVAL->cost_del = items > 3 ? SvUV(ST(3)) : 1;
      RETVAL->cost_sub = items > 4 ? SvUV(ST(4)) : 1;
   OUTPUT:
      RETVAL

void
DESTROY(self)
   Text::Levenshtein::Flexible self
   CODE:
      if(self) Safefree(self);

unsigned int
distance(self, src, dst)
   Text::Levenshtein::Flexible self
	SV * src
	SV * dst
   INIT:
      STRLEN src_bytes, src_chars, dst_bytes, dst_chars;
      const char *src_c, *dst_c;
      int *s_char_len = NULL;
   CODE:
      SETUP_SRC_DST;
      CALCULATE_CHAR_LENGTHS(src, dst, src_bytes, dst_bytes, src_chars, dst_chars);
      SETUP_S_CHAR_LEN(s_char_len, src_bytes, src_chars, dst_bytes, dst_chars)
	   RETVAL = levenshtein_internal(
         src_c, dst_c, s_char_len, src_bytes, dst_bytes, src_chars, dst_chars,
         self->cost_ins, self->cost_del, self->cost_sub
      );
   OUTPUT:
      RETVAL

unsigned int
distance_l(self, src, dst)
   Text::Levenshtein::Flexible self
	SV * src
	SV * dst
   INIT:
      STRLEN src_bytes, src_chars, dst_bytes, dst_chars;
      const char *src_c, *dst_c;
      int *s_char_len = NULL;
   CODE:
      SETUP_SRC_DST;
      CALCULATE_CHAR_LENGTHS(src, dst, src_bytes, dst_bytes, src_chars, dst_chars);
      SETUP_S_CHAR_LEN(s_char_len, src_bytes, src_chars, dst_bytes, dst_chars)
	   RETVAL = levenshtein_less_equal_internal(
         src_c, dst_c, s_char_len, src_bytes, dst_bytes, src_chars, dst_chars,
         self->cost_ins, self->cost_del, self->cost_sub,
         self->max
      );
      CHECK_RETVAL_MAX(self->max);
   OUTPUT:
      RETVAL

void
distances_l(self, src, ...)
   Text::Levenshtein::Flexible self
	SV * src
   PROTOTYPE: DISABLE
   INIT:
      STRLEN src_bytes, src_chars, dst_bytes, dst_chars;
      const char *src_c, *dst_c;
      unsigned int dist, dst_count;
      int need_s_char_len = 0;
      int *s_char_len = NULL;
      SV *dst;
      SV *tmp_result[2];
      AV *result;
   PPCODE:
      src_c = SvPV(src, src_bytes);
      src_chars = sv_len_utf8(src);
      if(src_bytes != src_chars) {
         s_char_len = setup_charlen(src_c, src_chars);
         need_s_char_len = 1;
      }
      for(dst_count=2; dst_count < items; ++dst_count) {
         dst = ST(dst_count);
         dst_c = SvPV(dst, dst_bytes);
         dst_chars = sv_len_utf8(dst);
         if( !s_char_len && ( dst_bytes != dst_chars ))
            s_char_len = setup_charlen(src_c, src_chars);
	      dist = levenshtein_less_equal_internal(
           src_c, dst_c,
           (need_s_char_len || dst_bytes != dst_chars) ? s_char_len : NULL,
           src_bytes, dst_bytes, src_chars, dst_chars,
           self->cost_ins, self->cost_del, self->cost_sub,
           self->max
         );
         if(dist <= self->max) {
            tmp_result[0] = dst;
            tmp_result[1] = sv_2mortal(newSVuv(dist));
            result = av_make(2, tmp_result);
            XPUSHs(sv_2mortal(newRV_noinc((SV*)result)));
         }
      }
      free_charlen(s_char_len);

void
closest(self, src, ...)
   Text::Levenshtein::Flexible self
	SV * src
   PROTOTYPE: DISABLE
   INIT:
      STRLEN src_bytes, src_chars, dst_bytes, dst_chars;
      const char *src_c, *dst_c;
      unsigned int dist, dst_count, closest_dist=UINT_MAX;
      int need_s_char_len = 0;
      int *s_char_len = NULL;
      SV *dst, *closest=NULL;
   PPCODE:
      src_c = SvPV(src, src_bytes);
      src_chars = sv_len_utf8(src);
      if(src_bytes != src_chars) {
         s_char_len = setup_charlen(src_c, src_chars);
         need_s_char_len = 1;
      }
      for(dst_count=2; dst_count < items; ++dst_count) {
         dst = ST(dst_count);
         dst_c = SvPV(dst, dst_bytes);
         dst_chars = sv_len_utf8(dst);
         if( !s_char_len && ( dst_bytes != dst_chars ))
            s_char_len = setup_charlen(src_c, src_chars);
	      dist = levenshtein_less_equal_internal(
           src_c, dst_c,
           (need_s_char_len || dst_bytes != dst_chars) ? s_char_len : NULL,
           src_bytes, dst_bytes, src_chars, dst_chars,
           self->cost_ins, self->cost_del, self->cost_sub,
           self->max
         );
         if(dist < closest_dist) {
            closest = dst;
            closest_dist = dist;
         }
      }
      free_charlen(s_char_len);
      if( closest ) {
         XPUSHs(closest);
         XPUSHs(sv_2mortal(newSVuv(closest_dist)));
      }
