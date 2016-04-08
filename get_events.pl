#!/usr/bin/perl

use strict;

use TBA;
use Data::Dumper;
$Data::Dumper::Indent = 1;
use Getopt::Long;

use JSON -support_by_pp;

my %opt = ();
GetOptions (\%opt, "new");

my $event_list = TBA::fetch('eventlist');
#print Dumper($event_list);

my $opts = "";
$opts .= " --new" if ($opt{new});
foreach my $e (@$event_list) {
 my $k = $e->{key};
 system ("perl _get_one_event.pl $opts $k");
}
