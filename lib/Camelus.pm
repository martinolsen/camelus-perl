package Camelus::Context;
use Moose::Role;

requires 'add_routes';

package Camelus::Exchange;
use Moose::Role;

requires 'in';

package Camelus::Message;
use Moose::Role;

has body => (is => 'rw');

package Camelus::Component;
use Moose::Role;

requires 'context';
requires 'create_endpoint';

package Camelus::Endpoint;
use Moose::Role;

has context => (is => 'ro', isa => 'Camelus::Context', required => 1);
has uri => (is => 'ro', isa => 'Str', required => 1);

requires 'create_exchange';
requires 'create_consumer';
requires 'create_polling_consumer';
requires 'create_producer';

package Camelus::Processor;
use Moose::Role;

requires 'process';

package Camelus::Producer;
use Moose::Role;

requires 'endpoint';
requires 'create_exchange';

with 'Camelus::Processor';

package Camelus::Consumer;
use Moose::Role;

has endpoint => (is => 'ro', isa => 'Camelus::Endpoint', required => 1);

requires 'start';


1;
