package Text::Levenshtein::Flexible;

use 5.014002;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw( levenshtein levenshtein_costs levenshtein_le levenshtein_le_costs levenshtein_le_all )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Text::Levenshtein::Flexible::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Text::Levenshtein::Flexible', $VERSION);

sub levenshtein_le_all {
    my $max_distance = shift;
    my $s = shift;
    my @results;
    for my $t (@_) {
        my $distance = levenshtein_le($s, $t, $max_distance);
        next unless defined $distance;
        push @results, [ $t, $distance ];
    }
    return @results;
}

sub levenshtein_le_costs_all {
    my ($max_distance, $cost_ins, $cost_del, $cost_sub, $s) = @_;
    splice(@_, 0, 4);
    my @results;
    for my $t (@_) {
        my $distance = levenshtein_le_costs($s, $t, $max_distance, $cost_ins, $cost_del, $cost_sub);
        next unless defined $distance;
        push @results, [ $t, $distance ];
    }
    return @results;
}

1;

=head1 NAME

Text::Levenshtein::Flexible - XS Levenshtein distance calculation with bounds and costs

=head1 SYNOPSIS

  use Text::Levenshtein::Flexible;


=head1 DESCRIPTION

Yet another Levenshtein module written in C, but a tad more flexible than the rest.

=head2 EXPORT

None by default.

=head2 Exportable constants

  INCLUDE_LEVENSTEIN_H
  false
  true

=head2 Exportable functions

  unsigned int levenshtein(
  const char *src, const char *dst)
  unsigned int levenshtein_less_equal(
  const char *src, const char *dst,
  unsigned int max_dist)
  unsigned int levenshtein_less_equal_with_costs(
      const char *src, const char *dst,
      int cost_ins, int cost_del, int cost_subst,
      unsigned int max_dist)
  unsigned int levenshtein_with_costs(
      const char *src, const char *dst,
      int cost_ins, int cost_del, int cost_subst)



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Matthias Bethke, E<lt>mb@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Matthias Bethke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
