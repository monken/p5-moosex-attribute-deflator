package MyBenchmark;

use Moose;
use JSON;
use DateTime;

use MooseX::Attribute::Deflator::Moose;
use MooseX::Attribute::Deflator;

has hashref => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Deflator'],
    default => sub { { foo => 'bar' } }
);

package main;
use strict;
use warnings;
use JSON::XS;
use Benchmark qw(:all);

my $obj     = MyBenchmark->new;
my $attr = $obj->meta->get_attribute('hashref');

cmpthese(1_000_000, {
    deflate => sub {
        $attr->deflate($obj);
    },
    get_value => sub {
        JSON::XS::encode_json($attr->get_value($obj, 'hashref'));
    },
    accessor => sub {
        JSON::XS::encode_json($obj->hashref);
    }
});