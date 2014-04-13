use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

BEGIN { use_ok('Text::Levenshtein::Flexible', qw/ :all /) };

is(levenshtein('aaa', 'abab'), 2, 'Simple distance calculation');
dies_ok(sub { levenshtein('a'x10000, 'b') }, 'Max string size enforced for src');
dies_ok(sub { levenshtein('a', 'b'x10000) }, 'Max string size enforced for dst');

is(levenshtein_le('aaa', 'abab', 3), 2, 'Limited distance with limit > dist');
is(levenshtein_le('aaa', 'abab', 2), 2, 'Limited distance with limit == dist');
is(levenshtein_le('aaa', 'abab', 1), undef, 'Limited distance with limit < dist');
dies_ok(sub { levenshtein_le('a'x10000, 'b', 3) }, 'Max string size enforced for src');
dies_ok(sub { levenshtein_le('a', 'b'x10000, 3) }, 'Max string size enforced for dst');

is(levenshtein_costs('xxxx', 'xxaxx', 1, 100, 100), 1, 'Costs: insert');
is(levenshtein_costs('xxaxx', 'xxxx', 100, 1, 100), 1, 'Costs: delete');
is(levenshtein_costs('xxaxx', 'xxbxx', 100, 100, 1), 1, 'Costs: substitute');
