#!/usr/bin/perl

use warnings;
use strict;
use POSIX qw(strftime);
use LWP;

# this one you can get with firebug or from proxy log files:
my $start_url = 'http://188.254.118.36/variant.m3u8?cid=81314a30-4744-11e1-b893-047d7b4d39e6&var=orig';

# will dump files there:
my $target_dir = '/mnt/enormous/20120229';

# will add hourly timestamp there
my $target_basename = 'camera01';

# camera timezone:
my $uik_tz = 'Asia/Krasnoyarsk';

{
  while(1)
  {
    # generate filename to write to (hourly)
    $ENV{'TZ'} = $uik_tz;
    my $now_string = strftime "%Y-%d-%m %H:%M:%S", localtime;
    my $out_name = "$target_dir/$target_basename" . (strftime "_%Y-%d-%m_%H_00.ts", localtime);
    print "remote time is $now_string, writing to $out_name...\n";
    # get playlist
    # get all files
    # wait for time to pass (if any)
    # repeat
    die "ZZZ";
  }
}
