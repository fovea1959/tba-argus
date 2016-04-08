#!/usr/bin/perl

use strict;

use TBA;
use Data::Dumper;
$Data::Dumper::Indent = 1;

use Try::Tiny;

use JSON -support_by_pp;

use Carp 'verbose';
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use Encode;
binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

use Time::Local;
use POSIX qw ( strftime );
use Text::CSV;

my $event_list = TBA::loadFromLocal('eventlist');
#print Dumper($event_list);

my $csv = Text::CSV->new() || die Text::CSV->error_diag();

foreach my $e (@$event_list) {
 print Dumper($e);
 my $k = $e->{key};
 my $fn = TBA::make_filename_for_event_matches($k);
 print STDERR "fetching $k $fn\n";
 my $event = TBA::loadFromLocal($fn);
 dumpEvent($event);
 last;
}

sub dumpEvent {
 my ($event) = @_;
 foreach my $match (@$event) {
  print Dumper($match);
  print "time=", $match->{time};
  print splunk("event_key", $match->{event_key});
  print splunk("match_key", $match->{key});
  print "\n";
  my $colors = [ keys %{$match->{alliances}} ];
  my $scores = {};
  my $rps = { red => 0, blue => 0};
  foreach my $color (@$colors) {
   $scores->{$color} = $match->{alliances}->{$color}->{score};
  }
  my $redMargin = $scores->{red} - $scores->{blue};
  if ($redMargin > 0) {
   $rps->{red} = 2;
  } elsif ($redMargin < 0) {
   $rps->{blue} = 2;
  } else {
   $rps->{red} = 1;
   $rps->{blue} = 1;
  }
  print Dumper($scores);
  foreach my $color (@$colors) {
   my $s = $match->{score_breakdown}->{$color};
   foreach my $team (@{$match->{alliances}->{$color}->{teams}}) {
    print " $team $color $scores->{$color} $rps->{$color}\n";
   }
  }
  last;
 }
}

sub splunk {
 my ($fn, $v) = @_;
 $csv->combine($v);
 my $csvv = $csv->string();
 return " $fn=$csvv";
}
