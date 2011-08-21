use strict;
use warnings;
use Test::More;

use Dancer::Core::Role::Config;
use Dancer::FileUtils qw/dirname path/;
use File::Spec;

my $location = File::Spec->rel2abs(path(dirname(__FILE__), 'config'));

{
    package Prod;
    use Moo;
    with 'Dancer::Core::Role::Config';

    sub get_environment { "production" }
    sub config_location { $location }

    package Dev;
    use Moo;
    with 'Dancer::Core::Role::Config';

    sub get_environment { "development" }
    sub config_location { $location }

    package Failure;
    use Moo;
    with 'Dancer::Core::Role::Config';

    sub get_environment { "failure" }
    sub config_location { $location }

}

my $d = Dev->new;
is_deeply [$d->config_files], 
    [
     path($location, 'config.yml'), 
    ],
    "config_files() only sees existing files";

my $f = Prod->new;
is $f->does('Dancer::Core::Role::Config'), 1,
    "role Dancer::Core::Role::Config is consumed";

is_deeply [$f->config_files], 
    [
     path($location, 'config.yml'), 
     path($location, 'environments', 'production.yml'),
    ],
    "config_files() works";

note "bad YAML file";
my $fail = Failure->new;
is $fail->get_environment, 'failure';

is_deeply [$fail->config_files], 
    [
     path($location, 'config.yml'), 
     path($location, 'environments', 'failure.yml'),
    ],
    "config_files() works";


eval { $fail->config->{stuff} };
like $@, qr{Unable to parse the configuration file};

note "config parsing";

is $f->config->{show_errors}, 0;
is $f->config->{main}, 1;
is $f->config->{charset}, 'utf-8', 
    "normalized UTF-8 to utf-8";

eval { $f->_normalize_config({charset => 'BOGUS'}) };
like $@, qr{Charset defined in configuration is wrong : couldn't identify 'BOGUS'};
done_testing;
