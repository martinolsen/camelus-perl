use Test::More tests => 1;

use Camelus::DefaultContext;
use Camelus::Component::Direct;

my $context = Camelus::DefaultContext->new;
$context->set_component(direct => Camelus::Component::Direct::DirectComponent->new(context => $context));

my $endpoint = $context->get_endpoint('direct:foo');
ok($endpoint->isa('Camelus::Component::Direct::DirectEndpoint'), 'endpoint is a DirectEndpoint');
