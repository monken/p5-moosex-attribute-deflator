use Test::More;
use strict;
use warnings;

package Test;
use Moose;
use MooseX::Attribute::LazyInflator;
use Moose::Util::TypeConstraints;

subtype 'C', as 'ArrayRef';
coerce 'C', from 'Str', via { [] };

no Moose::Util::TypeConstraints;

has attr => ( is => 'rw', coerce => 1, isa => 'C', traits => ['LazyInflator'] );

package main;

for ( 1 .. 2 ) {

    my $foo = Test->new( attr => "foo" );
    ok( Test->meta->get_attribute('attr')->is_inflated($foo) );

    $foo = Test->new( attr => ['foo'] );
    ok( Test->meta->get_attribute('attr')->is_inflated($foo) );
    Test->meta->make_immutable;

}

done_testing;
