#!/usr/bin/perl

use warnings;
use strict;
use POSIX qw(strftime);
use LWP::Simple;
use File::Basename;

# this one you can get with firebug or from proxy log files:
my $playlist_url = 'http://188.254.112.50/variant.m3u8?cid=08ace5a8-46c5-11e1-be30-f0def1c2c06e&var=orig';

# will dump files there:
my $target_dir = '/mnt/enormous/20120229';

# will add hourly timestamp there
my $target_basename = 'camera01';

# camera timezone:
my $uik_tz = 'Asia/Krasnoyarsk';

# if you have s3 access and s3cmd installed/configured, I can upload torrent files to this bucket:
my $s3_bucket = 's3://webvybory2012.vnaum.com';
# otherwise, uncomment this:
# my $s3_bucket = undef;

sub make_torrent($);

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

  my $prev_outname = undef;

  while(1)
  {
    # generate filename to write to (hourly)
    $ENV{'TZ'} = $uik_tz;
    my $now_string = strftime "%Y-%d-%m %H:%M:%S", localtime;
    my $out_name = "$target_dir/$target_basename" . (strftime "_%Y-%d-%m_%H_00.ts", localtime);
    if ($prev_outname and ($prev_outname ne $out_name))
    {
      print "We're done with $prev_outname, let's calculate its torrent...";
      make_torrent($prev_outname);
    }

    print "remote time is $now_string, writing to $out_name...\n";

    # get playlist
    my $playlist = get($playlist_url);
    warn "Couldn't get playlist!" unless defined $playlist;

    my $stt = time;

    # get all files
    my @lines = split "\n", $playlist;
    foreach (@lines) {
      if (m!^/segment\.ts\?.*ts=([\d.]+)-([\d.]+)!)
      {
        my ($st, $et) = ($1, $2);
        my $segment_url = $server . $_;
        print "Getting $segment_url...\n";
        my $stream_data = get($segment_url);
        open OUT, ">>", $out_name or die "can't open $out_name for writing: $!";
        print OUT $stream_data;
        close OUT;
      }
    }
    # wait for a minute to pass, repeat:
    print "waiting for $stt+60, now it is ", time, "\n";
    sleep 0.5 while (time < $stt+60);
    # this timeout probably requires fixing - but for now all segments are 15 seconds,
    # and there's new playlist every minute.

    $prev_outname = $out_name;
  }
}

sub make_torrent($)
{
  my ($file) = @_;
  {
    my @cmd = (qw(btmakemetafile.bittornado http://tracker.thepiratebay.org/announce),
      $file,
      qw(--announce_list http://tracker.thepiratebay.org/announce|udp://tracker.openbittorrent.com:80|udp://tracker.publicbt.com:80|udp://tracker.istole.it:80|udp://tracker.ccc.de:80|http://tracker.hexagon.cc:2710/announce)
    );
    system(@cmd) == 0
      or warn "system @cmd failed: $?";
  }

  if($s3_bucket)
  {
    my $basename = basename($file);
    my @cmd = (qw(s3cmd put), "$file.torrent", "$s3_bucket/$basename.torrent");
    system(@cmd) == 0
      or warn "system @cmd failed: $?";
  }
}
