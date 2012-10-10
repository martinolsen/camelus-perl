use Camelus;
use Camelus::Default;

package Camelus::Component::Direct::DirectComponent;
use Moose;

use Carp;

has context => (is => 'ro', isa => 'Camelus::Context', required => 1);

sub create_endpoint {
    my ($self, $uri) = @_;

    croak 'Usage: create_endpoint($uri)' unless(defined $uri);
    croak "invalid endpoint URI: $uri" unless($uri =~ m|^direct:.+|);

    return Camelus::Component::Direct::DirectEndpoint->new(
        context => $self->context,
        uri => $uri,
    );
}

with 'Camelus::Component';

package Camelus::Component::Direct::DirectEndpoint;
use Moose;

use Carp;

use Camelus::EventDrivenPollingConsumer;

has consumers => (
    traits => ['Hash'],
    is => 'ro',
    isa => 'HashRef[Camelus::Consumer]',
    lazy => 1,
    default => sub { {} },
);

sub create_exchange {
    my ($self, $pattern) = @_;

    # TODO $pattern //= $self->pattern;

    return Camelus::DefaultExchange->new;
}

sub create_consumer {
    my ($self, $processor) = @_;

    croak 'Usage: create_consumer($processor)' unless(defined $processor);
    croak '$processor is not a Camelus::Processor' unless($processor->does('Camelus::Processor'));

    return Camelus::Component::Direct::DirectConsumer->new(endpoint => $self, processor => $processor);
}

sub create_polling_consumer { # TODO - should be in ::DefaultEndpoint
    my ($self) = @_;

    return Camelus::EventDrivenPollingConsumer->new(endpoint => $self);
}

sub create_producer {
    my ($self) = @_;

    return Camelus::Component::Direct::DirectProducer->new(endpoint => $self);
}

sub add_consumer {
    my ($self, $consumer) = @_;

    $self->consumers->{$consumer->endpoint->uri} = $consumer;
}

sub get_consumer {
    my ($self) = @_;

    return $self->consumers->{$self->uri};
}

with 'Camelus::Endpoint';

package Camelus::Component::Direct::DirectProducer;
use Moose;

use Carp;

has endpoint => (is => 'ro', isa => 'Camelus::Endpoint', required => 1);

sub create_exchange {
    my ($self) = @_;

    return $self->endpoint->create_exchange;
}

sub process {
    my ($self, $exchange) = @_;

    confess 'No consumers available for endpoint: ' . $self->endpoint . ' to process: ' . $exchange
        unless(defined $self->endpoint->get_consumer);

    $self->endpoint->get_consumer->processor->process($exchange);
}

with 'Camelus::Producer';

package Camelus::Component::Direct::DirectConsumer;
use Moose;

extends 'Camelus::DefaultConsumer';

override start => sub {
    my ($self) = @_;

    $self->endpoint->add_consumer($self);
};

with 'Camelus::Consumer';


1;
