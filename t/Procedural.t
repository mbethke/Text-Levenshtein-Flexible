#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 18;
use Test::Exception;

BEGIN { use_ok('Text::Levenshtein::Flexible', qw/ :all /) };

is(levenshtein('aaa', 'abab'), 2, 'Simple distance calculation');
dies_ok(sub { levenshtein('a'x10000, 'b') }, 'Max string size enforced for src in levenshtein()');
dies_ok(sub { levenshtein('a', 'b'x10000) }, 'Max string size enforced for dst in levenshtein()');

is(levenshtein_l('aaa', 'abab', 3), 2, 'Limited distance with limit > dist');
is(levenshtein_l('aaa', 'abab', 2), 2, 'Limited distance with limit == dist');
is(levenshtein_l('aaa', 'abab', 1), undef, 'Limited distance with limit < dist');

dies_ok(sub { levenshtein_l('a'x10000, 'b', 3) }, 'Max string size enforced for src in levenshtein_l()');
dies_ok(sub { levenshtein_l('a', 'b'x10000, 3) }, 'Max string size enforced for dst in levenshtein_l()');

is(levenshtein_c('xxxx', 'xxaxx', 1, 100, 100), 1, 'Costs: insert');
is(levenshtein_c('xxaxx', 'xxxx', 100, 1, 100), 1, 'Costs: delete');
is(levenshtein_c('xxaxx', 'xxbxx', 100, 100, 1), 1, 'Costs: substitute');

dies_ok(sub { levenshtein_c('a'x10000, 'b', 2, 3, 4) }, 'Max string size enforced for src in levenshtein_c()');
dies_ok(sub { levenshtein_c('a', 'b'x10000, 2, 3, 4) }, 'Max string size enforced for dst in levenshtein_c()');
dies_ok(sub { levenshtein_lc('a'x10000, 'b', 100000, 2, 3, 4) }, 'Max string size enforced for src in levenshtein_lc()');
dies_ok(sub { levenshtein_lc('a', 'b'x10000, 100000, 2, 3, 4) }, 'Max string size enforced for dst in levenshtein_lc()');

my @teststrings = qw/ axb axxxxxb abcde ab a 123456 /;
is_deeply(
    [ levenshtein_l_all(3, 'abc', @teststrings) ],
    [ ['axb', 2], ['abcde', 2], ['ab', 1], ['a', 2]],
    "Returning all matches in levenshtein_l_all()"
);

is_deeply(
    [ levenshtein_lc_all(8, 2, 4, 8, 'abc', @teststrings) ],
    [ [ 'axb', 6 ], [ 'abcde', 4 ], [ 'ab', 4 ], [ 'a', 8 ] ],
    "Returning all matches in levenshtein_lc_all()"
);

