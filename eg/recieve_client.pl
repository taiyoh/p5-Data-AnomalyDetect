#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::Util;
use JSON;
my $json = JSON->new->ascii(1)->utf8;

my $cv = AE::cv;
my $t;

my $g = tcp_connect 'unix/', '/tmp/data_anomaly_recieve.sock', sub {
    my ($fh) = @_;

    my $hdl = AnyEvent::Handle->new(
        fh => $fh,
        on_eof => sub {
            my ($hdl, $fatal, $msg) = @_;
            AE::log error => $msg;
            $hdl->destroy;
            $cv->send;
        },
        on_error => sub {
            my ($hdl, $fatal, $msg) = @_;
            AE::log error => $msg;
            $hdl->destroy;
            $cv->send;
        }
    );

    $hdl->on_read(sub {
        $hdl->push_read(line => sub {
            my ($hdl, $line) = @_;
            my $ret = $json->decode($line);
            print "target -> $ret->{target}, outlier -> $ret->{outlier}, score -> $ret->{score}\n";
        });
    });

    $t = AE::timer 0, 3, sub {
        my $cv2 = run_cmd [qw(uptime)], ">" , \my $res;
        $cv2->cb(sub {
            chomp $res;
            my ($a) = ($res =~ /load averages: (.+)$/);
            my ($a1, $a2, $a3) = split /\s/, $a;
            $hdl->push_write("load_average $a1\015\012");
        });
    };
};

$cv->recv;
