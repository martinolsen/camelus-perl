use Camelus;

package Camelus::EventDrivenPollingConsumer;
use Moose;

use Time::HiRes qw(usleep);

has queue => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef[Obj]',
    lazy => 1,
    default => sub { [] },
);

has consumer => (
    is => 'rw',
    isa => 'Camelus::Consumer',
    lazy => 1,
    builder => '_build_consumer',
);

sub _build_consumer {
    my ($self) = @_;

    return $self->endpoint->create_consumer($self);
}

has ['started', 'starting'] => (is => 'rw', isa => 'Bool', default => 0);

sub start {
    my ($self) = @_;

    return if($self->started or $self->starting);

    $self->starting(1);

    $self->consumer->start;

    $self->started(1);
    $self->starting(0);
}

sub receive {
    my ($self, $timeout) = @_;
    my $start = time;

    $timeout //= 0;

    do {
        return pop @{ $self->queue } if(scalar @{ $self->queue });

        usleep(250_000);
    } while($start + $timeout < time);

    return undef;
}

sub process {
    my ($self, $exchange) = @_;

    push @{ $self->queue } => $exchange;
}

with 'Camelus::Processor', 'Camelus::Consumer';


1;
