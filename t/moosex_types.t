use Test::More;
use warnings;
use strict;
use lib qw(t/lib);

package Test;

use Moose;
use JSON;

use Types q(:all);

has hashref => ( is => 'rw', isa => MyHashRef, traits => ['MooseX::Attribute::Deflator::Meta::Role::Attribute'] );

package main;

my $obj = Test->new( hashref => { foo => 'bar' } );

is_deeply( $obj->meta->get_attribute('hashref')->get_value($obj), { foo => 'bar' } );

is( $obj->meta->get_attribute('hashref')->deflate($obj), '{"foo":"bar"}' );



done_testing;