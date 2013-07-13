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
