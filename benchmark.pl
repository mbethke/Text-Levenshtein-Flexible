#!/usr/bin/env perl 
use strict;
use warnings;
use utf8;
use Benchmark ':all';
use Test::More tests => 2;
use Text::Levenshtein::Flexible ':all';
use Text::Levenshtein::XS 'distance';

my $s = "xa"x100;
my $t = "yb"x100;
is(levenshtein($s,$t), distance($s,$t), "Same result Text::Levenshtein::Flexible vs. Text::Levenshtein::XS");

cmpthese(100000, {
        'Text::Levenshtein::Flexible'   => sub { levenshtein($s, $t); },
        'Text::Levenshtein::XS'         => sub { distance($s, $t); },
    }
);

my $o = Text::Levenshtein::Flexible->new(1000000, 1, 2, 3);
is($o->distance_lc($s,$t), levenshtein_lc($s, $t, 1000000, 1, 2, 3), "Same result OO vs. procedural");
cmpthese(100000, {
        OO      => sub { $o->distance_lc($s, $t); },
        Proc    => sub { levenshtein_lc($s, $t, 1000000, 1, 2, 3); },
    }
);
