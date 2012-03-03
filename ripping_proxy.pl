#!/usr/bin/perl

use warnings;
use strict;
use POSIX qw(strftime);
use LWP::Simple;
use File::Basename;
use HTTP::Proxy;

# this one you can get with firebug or from proxy log files:
my $playlist_url = 'http://188.254.112.50/variant.m3u8?cid=f49b6b5e-4401-11e1-8a16-001999c6bd4b&var=orig';

# will dump files there:
my $target_dir = '/mnt/enormous/20120229';

# will add hourly timestamp there
my $target_basename = 'camera01';

# camera timezone:
my $uik_tz = 'Asia/Omsk';

# if you have s3 access and s3cmd installed/configured, I can upload torrent files to this bucket:
my $s3_bucket = 's3://webvybory2012.vnaum.com';
# otherwise, uncomment this:
# my $s3_bucket = undef;

sub make_torrent($);

{

  # initialisation
  my $proxy = HTTP::Proxy->new( port => 5000 );

  # fixes a common typo ;-)
  # but chances are that this will modify a correct URL
  {
    package MyFilter;

    use base qw( HTTP::Proxy::BodyFilter );

    # a simple modification, that may break things
    sub filter {
      my ( $self, $dataref, $message, $protocol, $buffer ) = @_;
      print $message->uri(), "\n";
    }

  }
  $proxy->push_filter( request => MyFilter->new() );

  # this is a MainLoop-like method
  $proxy->start;
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
