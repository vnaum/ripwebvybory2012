#!/usr/bin/perl

use warnings;
use strict;
use POSIX qw(strftime);
use LWP::Simple;

# this one you can get with firebug or from proxy log files:
my $playlist_url = 'http://188.254.112.50/variant.m3u8?cid=08ace5a8-46c5-11e1-be30-f0def1c2c06e&var=orig';

# will dump files there:
my $target_dir = '/mnt/enormous/20120229';

# will add hourly timestamp there
my $target_basename = 'camera01';

# camera timezone:
my $uik_tz = 'Asia/Krasnoyarsk';

{
  my $server = undef;
  if ($playlist_url =~ m!(http://[^/]+)/!)
  {
    $server = $1;
  }
  else
  {
    die "weird playlist_url\n";
  }

  while(1)
  {
    # generate filename to write to (hourly)
    $ENV{'TZ'} = $uik_tz;
    my $now_string = strftime "%Y-%d-%m %H:%M:%S", localtime;
    my $out_name = "$target_dir/$target_basename" . (strftime "_%Y-%d-%m_%H_00.ts", localtime);
    print "remote time is $now_string, writing to $out_name...\n";

    # get playlist
    my $playlist = get($playlist_url);
    die "Couldn't get playlist!" unless defined $playlist;

    # get all files
    my @lines = split "\n", $playlist;
    foreach (@lines) {
      if (m!^/segment\.ts\?.*ts=([\d.]+)-([\d.]+)!)
      {
        my ($st, $et) = ($1, $2);
        sleep 0.5 while (time < $st);
        my $segment_url = $server . $_;
        print "Getting $segment_url...\n";
        my $stream_data = get($segment_url);
        open OUT, ">>", $out_name or die "can't open $out_name for writing: $!";
        print OUT $stream_data;
        close OUT;
      }
    }

    # wait for time to pass (if any)
    # repeat
    die "ZZZ";
  }
}
