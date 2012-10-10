use Test::More tests => 4;

use Camelus::DefaultContext;
use Camelus::Component::Direct;

my $context = Camelus::DefaultContext->new;
$context->set_component(direct => Camelus::Component::Direct::DirectComponent->new(context => $context));

my $endpoint = $context->get_endpoint('direct:foo');
my $producer = $endpoint->create_producer;
ok($producer, 'create a producer for endpoint');

my $consumer = $endpoint->create_polling_consumer;
ok($producer, 'create a polling consumer for endpoint');

$consumer->start;

my $input = $producer->create_exchange;
$input->in->body('FOO');
$producer->process($input);

my $output = $consumer->receive(10);
ok($output, 'created an Exchange');
is($output->in->body, 'FOO', '$foo was set to "FOO"');
