package Data::AnomalyDetect::Recieve;

use strict;
use warnings;

use Carp ();
use AnyEvent::Handle;
use AnyEvent::Socket;
use Data::AnomalyDetect;

use JSON;
my $json = JSON->new->ascii(1)->utf8;

sub new {
    my $package = shift;
    my %args = $_[1] ? @_ : %{ $_[0] };

    my $self = bless \%args, $package;

    for my $tag (keys %{ $args{tags} }) {
        $self->add_tag($tag, $args{tags}{$tag});
    }

    $self->{_guards} = {};

    return $self;
}

sub add_tag {
    my ($self, $tag) = @_;
    my %conf = $_[1] ? @_ : %{ $_[0] || {} };
    $self->{tags}{$tag} = Data::AnomalyDetect->new(%conf);
}

sub run {
    my $self = shift;

    my $cv = AE::cv;

    my $callback = sub {
        my ($fh) = @_;

        my $hdl = AnyEvent::Handle->new(
            fh => $fh,
            on_eof => sub {
                my ($hdl, $fatal, $msg) = @_;
                $msg ||= '';
                AE::log error => "[$fatal] on_eof: $msg";
                $hdl->destroy;
            },
            on_error => sub {
                my ($hdl, $fatal, $msg) = @_;
                $msg ||= '';
                AE::log error => "[$fatal] on_error: $msg";
                $hdl->destroy;
            }
        );

        $hdl->on_read(sub {
            $hdl->push_read(line => sub {
                my ($hdl, $line) = @_;
                my ($tagname, $val) = split /\s+/, $line;
                return if !$tagname || !defined($val);
                my $tag = $self->{tags}{$tagname} || $self->add_tag($tagname);
                my $res = $tag->emit($val) || {};
                $hdl->push_write($json->encode($res). "\015\012");
            });
        });
    };

    if ($self->{port}) {
        my $bind = $self->{bind} || undef;
        $self->{_guards}{port} = tcp_server $bind, $self->{port}, $callback;
    }
    if ($self->{socket}) {
        $self->{_guards}{socket} = tcp_server 'unix/', $self->{socket}, $callback;
    }

    Carp::croak("no tcp server!") unless keys %{ $self->{_guards} };

    $self->{_guards}{_cv} = $cv;

    $cv->recv;
}

1;
