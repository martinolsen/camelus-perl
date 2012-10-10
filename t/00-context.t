use Test::More tests => 2;

BEGIN {
    use_ok('Camelus::DefaultContext');
};

my $context = Camelus::DefaultContext->new;
ok($context, 'created a Default Context');
