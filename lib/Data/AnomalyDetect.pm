package Data::AnomalyDetect;
use 5.008005;
use strict;
use warnings;
use Carp ();
use Data::ChangeFinder;
use List::Util 'sum';

our $VERSION = "0.01";

sub new {
    my $package = shift;
    my %args = $_[1] ? @_ : %{ $_[0] || {} };

    $args{outlier_term}     ||= 28;
    $args{outlier_discount} ||= 0.05;
    $args{smooth_term}      ||= 7;
    $args{score_term}       ||= 14;
    $args{score_discount}   ||= 0.1;
    $args{threshold}        ||= -1.0;

    Carp::croak("outlier discount ratio should be between (0, 1)")
        if ($args{outlier_discount} < 0 || 1 < $args{outlier_discount});
    Carp::croak("score discount ratio should be between (0, 1)")
        if ($args{score_discount} < 0 || 1 < $args{score_discount});
    Carp::croak("outlier term should be greater than 0")
        if ($args{outlier_term} < 1);
    Carp::croak("score term should be greater than 0")
        if ($args{score_term} < 1);
    Carp::croak("smooth term should be greater than 0")
        if ($args{smooth_term} < 1);

    $args{_outlier_buf} = [];
    $args{_outlier} = Data::ChangeFinder->new(@args{qw/outlier_term outlier_discount/});
    $args{_score}   = Data::ChangeFinder->new(@args{qw/score_term score_discount/});

    return bless \%args, $package;
}

sub emit {
    my ($self, $val) = @_;

    my $outlier = $self->{_outlier}->next($val);
    push @{ $self->{_outlier_buf} }, $outlier;
    shift @{ $self->{_outlier_buf} } if scalar(@{ $self->{_outlier_buf} }) > $self->{smooth_term};
    my $score = $self->{_score}->next(sum(@{ $self->{_outlier_buf} }) / scalar(@{ $self->{_outlier_buf} }));

    if ($self->{threshold} < 0 || ($self->{threshold} >= 0 && $score > $self->{threshold})) {
        return { outlier => $outlier, score => $score, target => $val };
    }
    else {
        return undef;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::AnomalyDetect - It's new $module

=head1 SYNOPSIS

    use Data::AnomalyDetect;

=head1 DESCRIPTION

Data::AnomalyDetect is ...

=head1 LICENSE

Copyright (C) taiyoh.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

taiyoh E<lt>sun.basix@gmail.comE<gt>

=cut

