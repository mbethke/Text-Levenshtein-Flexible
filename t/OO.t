#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Test::More;
use Test::Fatal;
use Test::LeakTrace;

BEGIN { use_ok('Text::Levenshtein::Flexible', qw/ :all /) };

# new and DESTROY
is(exception {
    is(_new(65535, 2, 4, 6)->distance('aaa', 'aab'), 6, 'Simple distance calculation');
}, undef, "new/DESTROY cycle");

# Simple calculations
my $t = _new(100, 2, 4, 6);
like(
    exception { $t->distance('a'x20000, 'b') },
    qr/^argument exceeds the maximum length of/,
    'Max string size enforced for src in distance()'
);
like(
    exception { $t->distance('a', 'b'x20000) },
    qr/^argument exceeds the maximum length of/,
    'Max string size enforced for dst in distance()'
);

# Distance-limited methods
is(_new(3, 1, 1, 1)->distance_l('aaa', 'abab'), 2, 'Limited distance with limit > dist');
is(_new(2, 1, 1, 1)->distance_l('aaa', 'abab'), 2, 'Limited distance with limit == dist');
is(_new(1, 1, 1, 1)->distance_l('aaa', 'abab'), undef, 'Limited distance with limit < dist');

$t = _new(100000, 2, 4, 6);

# Costs
is(_new(100, 1, 100, 100)->distance_c('xxxx', 'xxaxx'), 1, 'Costs: insert');
is(_new(100, 100, 1, 100)->distance_c('xxaxx', 'xxxx'), 1, 'Costs: delete');
is(_new(100, 100, 100, 1)->distance_c('xxaxx', 'xxbxx'), 1, 'Costs: substitute');

# List methods
my @teststrings = qw/ axb axxxxxb abcde ab a 123456 /;
is_deeply(
    [ _new(3, 1, 1, 1)->distance_l_all('abc', @teststrings) ],
    [ ['axb', 2], ['abcde', 2], ['ab', 1], ['a', 2]],
    "Returning all matches in distance_l_all()"
);

is_deeply(
    [ _new(8, 2, 4, 8)->distance_lc_all('abc', @teststrings) ],
    [ [ 'axb', 6 ], [ 'abcde', 4 ], [ 'ab', 4 ], [ 'a', 8 ] ],
    "Returning all matches in distance_lc_all()"
);

no_leaks_ok(sub { _new(8, 2, 4, 8)->distance_lc_all('abc', @teststrings) }, 'no memory leaks in distance_lc_all');
no_leaks_ok(sub { _new(3)->distance_l_all('abc', @teststrings) }, 'no memory leaks in distance_lc_all');

# Partial arguments to new()
is( _new(65535, 2, 20, 200)->distance_l('abc', 'abd'), 22, "Correct distance with 4 constructor args");
is( _new(65535, 2, 20)->distance_l('abc', 'abd'), 1, "Correct distance with 3 constructor args");
is( _new(65535, 2)->distance_l('abc', 'abcc'), 2, "Correct distance with 2 constructor args");
is( _new(65535)->distance_l('abc', 'abd'), 1, "Correct distance with 1 constructor arg");
is( _new()->distance_l('abc', 'ab'), 1, "Correct distance with 0 constructor args");

# Unicode
is(_new()->distance('Käßwåfer', 'Kaeswaafer'), 5, "Unicode strings, Latin");
is(_new()->distance('猫', '尻'), 1, "Unicode strings, Kanji");
is(_new()->distance('한글', '조선글'), 2, "Unicode strings, Hangul");

my ($s, $dist) = _new()->closest('axxxb', @teststrings);
is( $s, 'axb', 'closest() finds correct string' );
is( $dist, 2, 'closest() finds correct distance' );

done_testing;

sub _new { return Text::Levenshtein::Flexible->new(@_) }
