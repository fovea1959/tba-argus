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
 #next unless $k eq "2016micmp";
 my $tzname = $e->{timezone};
 my ($event, $stats, $rankings);
 {
  my $fn = TBA::make_filename_for_event_matches($k);
  print STDERR "fetching $k $fn $tzname\n";
  $event = TBA::loadFromLocal($fn);
  $fn = TBA::make_filename_for_event_stats($k);
  $stats = TBA::loadFromLocal($fn);
  $fn = TBA::make_filename_for_event_rankings($k);
  $rankings = TBA::loadFromLocal($fn);
  #last;
 }
 dumpEvent($event, $tzname );
 dumpStats($e, $event, $stats, $rankings, $tzname);
}

sub dumpStats {
 my ($e, $event, $stats, $rankings, $tzname) = @_;
 my $t = { };
 #print STDERR Dumper($event);
 foreach my $n (keys %{$stats->{oprs}}) {
  $t->{$n} = { 
   'opr' => $stats->{oprs}->{$n},
   'ccwm' => $stats->{ccwms}->{$n},
   'dpr' => $stats->{dprs}->{$n},
  }
 }
 #print STDERR Dumper($t);

 # wow, this is weird
 my $header = undef;
 foreach my $rrow (@$rankings) {
  if (! defined $header) {
   $header = $rrow;
  } else {
   my %rhash = ( );
   foreach my $i (0..scalar(@$header)-1) {
    $rhash{$header->[$i]} = $rrow->[$i];
   }
   my $n = $rhash{Team};
   while (my ($k, $v) = each %rhash) {
    $t->{$n}->{$k} = $v;
   }
   #print STDERR Dumper($rhash);
  }
 }

 foreach my $t1 (keys %$t) {
  my $d = $t->{$t1};
  my $c = $d->{Played};
  print "time=\"", $e->{end_date}, "\" dt=teamevent";
  print splunk("batch", $opts{batch}) if defined $opts{batch};
  print splunk("event_key", $e->{key});
  print splunk("team", $t1);
  print splunk("rank", $d->{Rank});
  print splunk("rp", $d->{'Ranking Score'});
  print splunk("auto", a($d->{'Auto'}, $c));
  print splunk("scaleChallenge", a($d->{'Scale/Challenge'}, $c));
  print splunk("goals", a($d->{'Goals'}, $c));
  print splunk("defense", a($d->{'Defense'}, $c));
  print splunk("played", $d->{'Played'});
  print splunkFromHash("opr", $d);
  print splunkFromHash("dpr", $d);
  print splunkFromHash("ccwm", $d);
  print "\n";
  #print STDERR Dumper($t);
 }
}

sub a {
 my ($v, $c) = @_;
 return 0 if $c == 0;
 return sprintf("%.3f", $v/$c);
}

sub dumpEvent {
 my ($event, $tzname) = @_;
 foreach my $match (@$event) {
  #print STDERR Dumper($match);

  my $time = $match->{time};
  my $datetime = DateTime->from_epoch ( epoch => $time, time_zone => $tzname);
  my $ts = $datetime->strftime("%F %T %z");
  #print STDERR "$time -> $datetime -> $ts\n";

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
    my $team_number = $team;
    $team_number =~ s/^frc//;
    print "time=\"", $ts, "\" dt=match";
    print splunk("batch", $opts{batch}) if defined $opts{batch};
    print splunkFromHash("event_key", $match);
    print splunk("match_key", $match->{key});
    print splunk("team", $team_number);
    print splunk("alliance", $color);
    print splunkNZ("win", $win->{$color});
    print splunkNZ("loss", $loss->{$color});
    print splunkNZ("tie", $tie);
    print splunk("score", $scores->{$color});
    print splunk("opp_score", $scores->{other_color($color)});
    print splunkFromHash("comp_level", $match);
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
 print splunkFromHash('autoPoints', $s, $p);
 print splunkFromHash('autoReachPoints', $s, $p);
 print splunkFromHash('autoCrossingPoints', $s, $p);
 print splunkFromHash('autoBoulderPoints', $s, $p);
 print splunkFromHash('autoBouldersLow', $s, $p);
 print splunkFromHash('autoBouldersHigh', $s, $p);
 print splunkFromHash('teleopPoints', $s, $p);
 print splunkFromHash('teleopCrossingPoints', $s, $p);
 print splunkFromHash('teleopBoulderPoints', $s, $p);
 print splunkFromHash('teleopBouldersLow', $s, $p);
 print splunkFromHash('teleopBouldersHigh', $s, $p);
 print splunkFromHash('teleopChallengePoints', $s, $p);
 print splunkFromHash('teleopScalePoints', $s, $p);
 print splunkFromHashNZ('breachPoints', $s, $p);
 print splunkFromHashNZ('capturePoints', $s, $p);
 print splunkFromHash('towerEndStrength', $s, $p);
}

sub splunkFromHashNZ {
 my ($n, $s, $p) = @_;
 return "" unless $s->{$n};
 return splunk ($p . $n, $s->{$n});
}

sub splunkFromHash {
 my ($n, $s, $p) = @_;
 $p = "" if ! defined $p;
 return splunk ($p . $n, $s->{$n});
}

sub splunkNZ {
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
