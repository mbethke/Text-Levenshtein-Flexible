use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

BEGIN { use_ok('Text::Levenshtein::Flexible') };

is(Text::Levenshtein::Flexible::levenshtein('aaa', 'abab'), 2, "Simple distance calculation");
