#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Data::AnomalyDetect::Watch;
use AnyEvent::Util;
use Data::Dumper;

my $watch = Data::AnomalyDetect::Watch->new;

$watch->register({tag => "load_average", tick => 3}, sub {
    my $anomaly = shift;
    my $cv = run_cmd [qw(uptime)], ">" , \my $res;
    $cv->cb(sub {
        chomp $res;
        my ($a) = ($res =~ /load averages: (.+)$/);
        my ($a1, $a2, $a3) = split /\s/, $a;
        my $ret = $anomaly->emit($a1);
        print "target -> $ret->{target}, outlier -> $ret->{outlier}, score -> $ret->{score}\n";
    });
});

$watch->run;
