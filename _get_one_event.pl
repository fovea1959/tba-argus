#!/usr/bin/perl

use strict;

use TBA;
use Getopt::Long;
use Data::Dumper;
$Data::Dumper::Indent=1;

use JSON -support_by_pp;

my %opt = ();
GetOptions (\%opt, "new");
print Dumper(\%opt);

my $eventkey = $ARGV[0];

TBA::getAndSave('api/v2/event/' . $eventkey . '/matches', 'event_' . $eventkey . '_matches', \%opt);
