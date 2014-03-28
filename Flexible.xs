#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <ctype.h>

/* Faster than memcmp(), for this use case. */
static bool inline rest_of_char_same(const char *s1, const char *s2, int len)
{
	while (len > 0)
	{
		len--;
		if (s1[len] != s2[len])
			return 0;
	}
	return 1;
}

#include "levenshtein_internal.c"
#define LEVENSHTEIN_LESS_EQUAL
#include "levenshtein_internal.c"

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
      if(DO_UTF8(src) || DO_UTF8(dst)) {
         src_chars = sv_len_utf8(src);
         dst_chars = sv_len_utf8(dst);
      } else {
         src_chars = src_bytes;
         dst_chars = dst_bytes;
      }
	   RETVAL = levenshtein_internal(src_c, dst_c, src_bytes, dst_bytes, src_chars, dst_chars, 1, 1, 1);
   OUTPUT:
      RETVAL

