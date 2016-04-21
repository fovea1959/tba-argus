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

use DateTime;

use Getopt::Long;

my %opts = ( );
GetOptions(\%opts, "batch=s");

my $event_list = TBA::loadFromLocal('eventlist');
#print Dumper($event_list);

my $csv = Text::CSV->new() || die Text::CSV->error_diag();

foreach my $e (@$event_list) {
 #print Dumper($e);
 my $k = $e->{key};
 next unless $k eq "2016micmp";
 my $tzname = $e->{timezone};
 my $fn = TBA::make_filename_for_event_matches($k);
 print STDERR "fetching $k $fn $tzname\n";
 my $event = TBA::loadFromLocal($fn);
 dumpEvent($event, $tzname );
 #last;
}

sub dumpEvent {
 my ($event, $tzname) = @_;
 foreach my $match (@$event) {
  #print Dumper($match);

  my $time = $match->{time};
  my $datetime = DateTime->from_epoch ( epoch => $time, time_zone => $tzname);
  my $ts = $datetime->strftime("%F %T %z");
  #print "$time -> $datetime -> $ts\n";

  my $colors = [ keys %{$match->{alliances}} ];
  my $win = {};
  my $loss = {};
  my $tie = 0;
  my $scores = {};
  my $rps = { red => 0, blue => 0};
  foreach my $color (@$colors) {
   $scores->{$color} = $match->{alliances}->{$color}->{score};
  }
  if ($scores->{red} == -1 && $scores->{blue} == -1) {
   printf STDERR "match %s did not happen\n", $match->{key};
   next;
  }
  my $redMargin = $scores->{red} - $scores->{blue};
  if ($redMargin > 0) {
   $rps->{red} = 2;
   $win->{red} = 1;
   $loss->{blue} = 1;
  } elsif ($redMargin < 0) {
   $rps->{blue} = 2;
   $win->{blue} = 1;
   $loss->{red} = 1;
  } else {
   $rps->{red} = 1;
   $rps->{blue} = 1;
   $tie = 1;
  }
  foreach my $color (@$colors) {
   my $s = $match->{score_breakdown}->{$color};
   if ($match->{comp_level} eq "qm") {
    if ($s->{teleopDefensesBreached}) {
     $rps->{$color}++;
    }
    if ($s->{teleopTowerCaptured}) {
     $rps->{$color}++;
    }
   }
  }
  #print STDERR Dumper($scores);
  foreach my $color (@$colors) {
   my $s = $match->{score_breakdown}->{$color};
   # fix this line
   my $os = $match->{score_breakdown}->{$color};
   foreach my $team (@{$match->{alliances}->{$color}->{teams}}) {
    print "time=\"", $ts, "\"";
    print splunk("batch", $opts{batch}) if defined $opts{batch};
    print splunk1("event_key", $match);
    print splunk("match_key", $match->{key});
    print splunk("team", $team);
    print splunk("alliance", $color);
    print splunknz("win", $win->{$color});
    print splunknz("loss", $loss->{$color});
    print splunknz("tie", $tie);
    print splunk("score", $scores->{$color});
    print splunk("opp_score", $scores->{other_color($color)});
    print splunk1("comp_level", $match);
    print splunk("rp", $rps->{$color});
    print splunk("opp_rp", $rps->{other_color($color)});
    scoreStuff($s, "");
    print splunk("teleopDefensesBreached", $s->{teleopDefensesBreached} ? 1 : 0);
    print splunk("teleopTowerCaptured", $s->{teleopTowerCaptured} ? 1 : 0);
    print "\n";
   }
  }
  #last;
 }
}

sub other_color {
 my ($c) = @_;
 return 'blue' if $c eq 'red';
 return 'red';
}

sub scoreStuff {
 my ($s, $p) = @_;
 print splunk1('autoPoints', $s, $p);
 print splunk1('autoReachPoints', $s, $p);
 print splunk1('autoCrossingPoints', $s, $p);
 print splunk1('autoBoulderPoints', $s, $p);
 print splunk1('autoBouldersLow', $s, $p);
 print splunk1('autoBouldersHigh', $s, $p);
 print splunk1('teleopPoints', $s, $p);
 print splunk1('teleopCrossingPoints', $s, $p);
 print splunk1('teleopBoulderPoints', $s, $p);
 print splunk1('teleopBouldersLow', $s, $p);
 print splunk1('teleopBouldersHigh', $s, $p);
 print splunk1('teleopChallengePoints', $s, $p);
 print splunk1('teleopScalePoints', $s, $p);
 print splunk1nz('breachPoints', $s, $p);
 print splunk1nz('capturePoints', $s, $p);
 print splunk1('towerEndStrength', $s, $p);
}

sub splunk1nz {
 my ($n, $s, $p) = @_;
 return "" unless $s->{$n};
 return splunk ($p . $n, $s->{$n});
}

sub splunk1 {
 my ($n, $s, $p) = @_;
 $p = "" if ! defined $p;
 return splunk ($p . $n, $s->{$n});
}

sub splunknz {
 my ($fn, $v) = @_;
 return "" unless $v;
 $csv->combine($v);
 my $csvv = $csv->string();
 return " $fn=$csvv";
}

sub splunk {
 my ($fn, $v) = @_;
 $csv->combine($v);
 my $csvv = $csv->string();
 return " $fn=$csvv";
}
