/*
 * Levenshtein distance calculation with costs
 *
 * Most code stolen verbatim from Joe Conway <mail@joeconway.com> via PostgreSQL
 * by Matthias Bethke <matthias@towiski.de>; slightly adapted for Perl
 * module use.
 *
 * Copyright (c) 2001-2011, PostgreSQL Global Development Group
 * Copyright (c) 2014 Matthias Bethke
 * ALL RIGHTS RESERVED;
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without a written agreement
 * is hereby granted, provided that the above copyright notice and this
 * paragraph and the following two paragraphs appear in all copies.
 *
 * IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING
 * LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE AUTHOR OR DISTRIBUTORS HAVE BEEN ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE AUTHOR AND DISTRIBUTORS HAS NO OBLIGATIONS TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */

#include <ctype.h>
#include "ppport.h"

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
   /* we have "inline" */
#else
   #define inline static
#endif

/* Faster than memcmp(), for this use case. */
inline int rest_of_char_same(const char *s1, const char *s2, int len)
{
	while (len > 0)
	{
		len--;
		if (s1[len] != s2[len])
			return 0;
	}
	return 1;
}

inline static int *setup_charlen(const char *cp, int len) {
   int *s_char_len;
   int i;

   Newx(s_char_len, len + 1, int);
   for (i = 0; i < len; ++i)
   {
      s_char_len[i] = UTF8SKIP(cp);
      cp += s_char_len[i];
   }
   s_char_len[i] = 0;
   return s_char_len;
}

/* just for symmetry */
inline static void free_charlen(int *charlen) {
   if(charlen) Safefree(charlen);
}

#include "levenshtein_internal.c"
#define LEVENSHTEIN_LESS_EQUAL
#include "levenshtein_internal.c"

