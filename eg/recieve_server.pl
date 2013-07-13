#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Data::AnomalyDetect::Recieve;

my $recieve = Data::AnomalyDetect::Recieve->new(
    socket => '/tmp/data_anomaly_recieve.sock'
);
$recieve->run;
