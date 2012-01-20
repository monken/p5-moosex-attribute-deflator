package Test;

use Moose;
use JSON;
use DateTime;

use MooseX::Attribute::Deflator::Moose;
use MooseX::Attribute::Deflator;

deflate 'DateTime', via { $_->epoch }, inline {'$value->epoch'};
inflate 'DateTime', via { DateTime->from_epoch( epoch => $_ ) },
    inline {'DateTime->from_epoch( epoch => $value )'};

my $dt = DateTime->now;

has hashref => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Deflator'],
    lazy    => 1,
    default => sub { { foo => 'bar' } }
);

has hashrefarray => (
    is      => 'rw',
    isa     => 'HashRef[ArrayRef[HashRef]]',
    traits  => ['Deflator'],
    default => sub { { foo => [ { foo => 'bar' } ] } },
);

has datetime => (
    is       => 'rw',
    isa      => 'DateTime',
    required => 1,
    default  => sub {$dt},
    traits   => ['Deflator']
);

has datetimearrayref => (
    is       => 'rw',
    isa      => 'ArrayRef[DateTime]',
    required => 1,
    default  => sub { [ $dt, $dt->clone->add( hours => 1 ) ] },
    traits   => ['Deflator']
);

has scalarint => (
    is       => 'rw',
    isa      => 'ScalarRef[Int]',
    required => 1,
    default  => sub { \1 },
    traits   => ['Deflator']
);

has bool =>
    ( is => 'rw', isa => 'Bool', default => 1, traits => ['Deflator'] );

has no_type => ( is => 'rw', traits => ['Deflator'], default => 'no_type' );

package main;
use strict;
use warnings;
use Test::More;

my $obj     = Test->new;
my $results = {
    hashref          => '{"foo":"bar"}',
    hashrefarray     => '{"foo":"[\"{\\\\\"foo\\\\\":\\\\\"bar\\\\\"}\"]"}',
    no_type          => 'no_type',
    bool             => 1,
    scalarint        => 1,
    datetime         => $dt->epoch,
    datetimearrayref => '['
        . $dt->epoch . ','
        . $dt->clone->add( hours => 1 )->epoch . ']',
};

for ( 1 .. 2 ) {
    foreach my $attr ( Test->meta->get_all_attributes ) {
        is( $attr->deflate($obj),
            $results->{ $attr->name },
            "result is $results->{$attr->name}"
        );

        is_deeply(
            $attr->inflate( $obj, $results->{ $attr->name } ),
            $attr->get_value($obj),
            "inflates $results->{$attr->name} correctly"
        );

        is( $attr->is_deflator_inlined,
            $Moose::VERSION >= 1.9,
            'deflator inlined'
        );
        is( $attr->is_inflator_inlined,
            $Moose::VERSION >= 1.9,
            'inflator inlined'
        );
    }
    diag "making immutable" if ( $_ eq 1 );
    Test->meta->make_immutable;
}

done_testing;