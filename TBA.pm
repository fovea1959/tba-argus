package TBA;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use Try::Tiny;

use JSON;

sub year {
 return 2016;
}

sub get {
 my ($url, $opt) = @_;
 my $ua = LWP::UserAgent->new();
 $ua->ssl_opts ( verify_hostname => 0, SSL_verify_mode => 0x00);
 if ($opt->{debug}) {
  $ua->add_handler("request_send",  sub { shift->dump; return });
  $ua->add_handler("response_done", sub { shift->dump; return });
 }

 my $request = HTTP::Request->new (GET =>"https://www.thebluealliance.com/$url");
 $request->header('X-TBA-App-Id', 'frc3620:scraper:v1.0');
 $request->header('User-Agent', 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:25.0) Gecko/20100101 Firefox/25.0');

 if ($opt) {
  if ($opt->{ims}) {
   $ua->default_header('If-Modified-Since' => HTTP::Date::time2str($opt->{ims}));
  }
 }

 my $response = $ua->request($request);
 if ($response->is_success) {
  return $response->decoded_content;
 } else {
  die $response->status_line;
 }
}

sub file_date {
 my ($name) = @_;
 my $fname = json_filename($name);

 return 0 unless -f $fname;
 return 0 if -z $fname;

 try {
  my $x = loadFromLocal($name);
 } catch {
  return 0;
 }

 return (stat($fname))[9];
}

sub loadFromLocal {
 my ($name) = @_;
 my $j = "";
 my $fname = json_filename($name);
 {
  local $/=undef;
  open (my $fh, '<', $fname) or die "trouble opening $fname: $!";
  $j = <$fh>;
  close $fh;
 }
 my $perl_scalar = from_json( $j, { utf8  => 1 } );
 return $perl_scalar;
}

sub make_filename_for_event_matches {
 my ($eventkey) = @_;
 my $rv = 'event_' . $eventkey . '_matches';
 print STDERR "$eventkey -> $rv\n";
 return $rv;
}

sub json_filename {
 my ($name) = @_;
 return year() . '/' . $name . '.json';
}

sub getAndSave {
 my ($url, $name, $opt) = @_;

 my $mdate = 0;
 my $fdate = file_date($name);
 if (! $opt->{force}) {
  if ($opt->{new} && $fdate) {
   warn "already have file $name";
   return;
  }
  $mdate = $fdate;
 }

 # put the If-Modified-Since here
 try {
  my $j = get($url, { ims => $mdate } );
  my $perl_scalar = from_json( $j, { utf8  => 1 } );
  my $j2 = to_json( $perl_scalar, { ascii => 1, pretty => 1 } );
  my $fn = json_filename($name);

  open (my $fh, '>', $fn) or die "trouble opening $fn: $!";
  print $fh $j2;
  close $fh;
 } catch {
  warn "getAndSave failed: $_";
 }
}

1;
