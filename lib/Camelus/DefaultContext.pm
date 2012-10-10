use Camelus;

package Camelus::DefaultContext;
use Moose;

use Carp;

has components => (
    traits => ['Hash'],
    is => 'ro',
    isa => 'HashRef[Camelus::Component]',
    default => sub { {} },
    handles => {
        get_component => 'get',
        set_component => 'set',
    },
);

has endpoints => (
    traits => ['Hash'],
    is => 'ro',
    isa => 'HashRef[Camelus::Endpoint]',
    default => sub { {} },
    handles => {
        get_endpoint => 'get',
        set_endpoint => 'set',
    },
);

around get_endpoint => sub {
    my $orig = shift;
    my $self = shift;
    my $name = shift;

    my $endpoint = $self->$orig($name);

    return $endpoint if($endpoint);

    my ($scheme) = $name =~ m|^(\w+):.+$|;

    croak "scheme not found in endpoint: $name" unless($scheme);

    if(my $component = $self->get_component($scheme)) {
        $endpoint = $component->create_endpoint($name);
    } else {
        croak "no component registered for $scheme";
    }

    return $self->set_endpoint($name => $endpoint);
};

has routes => (
    traits => ['Array'],
    is => 'rw',
    # TODO isa => 'ArrayRef[Camelus::Model::Route]',
    default => sub { [] },
    handles => {
        add_route => 'push',
        map_routes => 'map',
    },
);

sub add_routes {
    my ($self, $builder) = @_;

    $builder->add_routes_to_context($self);
}

with 'Camelus::Context';
#TODO with 'Camelus::Model::ModelContext';

=cut TODO
package Camelus::Model::ModelContext;
use Moose::Role;

requires 'add_route_definitions';
=cut


1;
