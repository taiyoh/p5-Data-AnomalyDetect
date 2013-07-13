#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Data::AnomalyDetect;

my $detect = Data::AnomalyDetect->new;

while(1) {
    my $res = `uptime`;
    chomp $res;
    my ($a) = ($res =~ /load averages: (.+)$/);
    my ($a1, $a2, $a3) = split /\s/, $a;
    if (my $ret = $detect->emit($a1)) {
        print "target -> $ret->{target}, outlier -> $ret->{outlier}, score -> $ret->{score}\n";
    }
    sleep 3;
}

__DATA__
# output
target -> 1.12, outlier -> 9.48310778734713, score -> 6.91179755926319
target -> 1.11, outlier -> -0.541562650368135, score -> 3.40657864244154
target -> 1.11, outlier -> -0.567111530327911, score -> 3.95873333105756
target -> 1.19, outlier -> -0.540999905002498, score -> 3.99833427509008
target -> 1.17, outlier -> -0.588621159274131, score -> 3.94086063829979
