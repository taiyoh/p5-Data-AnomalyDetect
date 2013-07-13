package Data::AnomalyDetect::Watch;

use strict;
use warnings;

use Carp ();
use AnyEvent;
use Data::AnomalyDetect;

sub new {
    my $package = shift;
    bless { callbacks => {}, _guards => {} }, $package;
}

sub register {
    my ($self, $conf, $callback) = @_;

    my $tag    = delete $conf->{tag} or Carp::croak("require tag parameter");
    my $tick   = delete $conf->{tick} or Carp::croak("require tick parameter");

    Carp::croak("require callback parameter") if !$callback || ref($callback) ne 'CODE';

    $self->{callbacks}{$tag} = {
        anomaly  => Data::AnomalyDetect->new($conf),
        tick     => $tick,
        callback => $callback
    };
}

sub run {
    my $self = shift;

    my $cv = $self->{_guards}{_cv} = AE::cv;

    for my $tag (keys %{ $self->{callbacks} }) {
        my $anomaly  = $self->{callbacks}{$tag}{anomaly};
        my $tick     = $self->{callbacks}{$tag}{tick};
        my $callback = $self->{callbacks}{$tag}{callback};
        my $g = AE::timer 0, $tick, sub {
            $callback->($anomaly, $tag);
        };
        $self->{_guards}{0+$g} = $g;
    }

    $cv->recv;
}

1;
