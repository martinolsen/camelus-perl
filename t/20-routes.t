package Camelus::Model::ProcessorDefinition;
use Moose::Role;

use Carp;

requires 'add_output';

sub to {
    my ($self, $endpoint) = @_;

    $self->add_output(Camelus::Model::ToDefinition->new(endpoint => $endpoint));

    return $self;
}

package Camelus::Model::ToDefinition;
use Moose;

use Carp;

has endpoint => (is => 'ro', required => 1);

sub add_output { confess 'TODO' }
sub from { confess 'TODO' }

with 'Camelus::Model::ProcessorDefinition';

package Camelus::Model::FromDefinition;
use Moose;

use Carp;

has endpoint => (is => 'ro', required => 1);

package Camelus::Model::RouteDefinition;
use Moose;

use Carp;

has inputs => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef[Camelus::Model::FromDefinition]',
    default => sub { [] },
    handles => {
        add_input => 'push',
        map_inputs => 'map',
    },
);

has outputs => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef[Camelus::Model::ProcessorDefinition]',
    default => sub { [] },
    handles => {
        add_output => 'push',
        map_outputs => 'map',
    },
);

sub from {
    my ($self, $endpoint) = @_;

    $self->add_input(Camelus::Model::FromDefinition->new(endpoint => $endpoint));

    return $self;
}

sub build {
    my ($self, $context) = @_;

    croak 'Usage: build($context)' unless($context);

    confess 'no inputs' unless(scalar(@{ $self->inputs }));
    confess 'too many inputs' if(scalar(@{ $self->inputs }) > 1);

    return Camelus::Model::Route->new(
        context => Camelus::Model::RouteContext->new(
            context => $context,
            route => $self,
            from => $self->inputs->[0],
        ),
    );
}

with 'Camelus::Model::ProcessorDefinition';

package Camelus::Model::RouteContext;
use Moose;

has context => (is => 'ro', isa => 'Camelus::Context', required => 1);
has route => (is => 'ro', isa => 'Camelus::Model::RouteDefinition', required => 1);
has from => (is => 'ro', isa => 'Camelus::Model::FromDefinition', required => 1);

has endpoint => (is => 'ro', isa => 'Camelus::Endpoint', lazy => 1, builder => '_build_endpoint');

sub _build_endpoint {
    my ($self) = @_;

    return $self->from->resolve_endpoint($self);
}

package Camelus::Model::Route;
use Moose;

use Carp;

has context => (is => 'ro', isa => 'Camelus::Model::RouteContext', required => 1);
has endpoint => (is => 'ro', isa => 'Camelus::Endpoint', required => 1);

package Camelus::Model::RoutesDefinition;
use Moose;

has context => (is => 'ro', isa => 'Camelus::Context', required => 1);
has routes => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef[Camelus::Model::RouteDefinition]',
    default => sub { [] },
    handles => {
        map_routes => 'map',
    },
);

sub from {
    my ($self, $endpoint) = @_;

    my $route = Camelus::Model::RouteDefinition->new->from($endpoint);

    push @{ $self->routes } => $route;

    return $route;
}


package Camelus::Model::RouteContext;
use Moose;



package Camelus::Builder::RoutesBuilder;
use Moose::Role;

requires 'add_routes_to_context';

package Camelus::Builder::RouteBuilder;
use Moose::Role;

use Carp;

requires 'configure';

has context => (is => 'ro', isa => 'Camelus::Context', required => 1);
# TODO has context => (is => 'ro', isa => 'Camelus::Model::ModelContext', required => 1);
has route_collection => (is => 'ro', isa => 'Camelus::Model::RoutesDefinition', lazy => 1, builder => '_build_route_collection');

sub _build_route_collection {
    my ($self) = @_;

    return Camelus::Model::RoutesDefinition->new(context => $self->context)
}

sub from {
    my ($self, $endpoint) = @_;

    unless(ref($endpoint) and $endpoint->isa('Camelus::Endpoint')) {
        $endpoint = $self->context->get_endpoint($endpoint)
            or carp "coult not find endpoint: $endpoint";
    }

    return $self->route_collection->from($endpoint);
}

sub add_routes_to_context {
    my ($self, $context) = @_;

    $self->route_collection->map_routes(sub {
        $context->add_route($_->build($context));
    });
}

with 'Camelus::Builder::RoutesBuilder';

package Camelus::MockRouteBuilder;
use Moose;

sub configure {
    my ($self) = @_;

    $self->from('direct:a')->to('direct:b');
}

with 'Camelus::Builder::RouteBuilder';

package main;
use Test::More;

use Camelus::DefaultContext;
use Camelus::Component::Direct;

my $context = Camelus::DefaultContext->new;
$context->set_component(direct => Camelus::Component::Direct::DirectComponent->new(context => $context));

my $route_builder = Camelus::MockRouteBuilder->new(context => $context);
ok($route_builder, 'can create MockRouteBuilder');

$route_builder->configure;

$context->add_routes($route_builder);
$context->map_routes(sub {
    $_->context->route->map_outputs(sub { $_->start });
    $_->context->route->map_inputs(sub { $_->start });
});

ok(my $a = $context->get_endpoint('direct:a'), 'create route "a"');
ok(my $b = $context->get_endpoint('direct:b'), 'create route "b"');

ok(my $producer = $a->create_producer, 'create consumer');
ok(my $consumer = $b->create_polling_consumer, 'create consumer');

$consumer->start;

ok(my $input = $producer->create_exchange, 'create "input" exchange');
$input->in->body('bar');

$producer->process($input);

ok(my $output = $consumer->receive(10), 'create "output" exchange');
is($output->in->body, 'bar', 'output message is "bar"');

done_testing;
