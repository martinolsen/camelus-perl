use Camelus;

package Camelus::DefaultMessage;
use Moose;

with 'Camelus::Message';

package Camelus::DefaultExchange;
use Moose;

has in => (
    is => 'ro',
    isa => 'Camelus::Message',
    lazy => 1,
    default => sub { Camelus::DefaultMessage->new },
);

with 'Camelus::Exchange';

package Camelus::DefaultConsumer;
use Moose;

has processor => (is => 'ro', isa => 'Camelus::Processor', required => 1);

sub start {
    my ($self) = @_;

    $self->processor->start;
}


1;
