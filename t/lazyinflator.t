use Test::More;
use strict;
use warnings;

package Test;

use Moose;
use DateTime;
use MooseX::Attribute::LazyInflator;
use MooseX::Attribute::Deflator::Moose;

use MooseX::Types::Moose qw(Str Int HashRef ArrayRef Maybe);
     
has hash => ( is => 'rw', isa => HashRef, traits => [qw(LazyInflator)] );
has lazyhash => ( is => 'rw', isa => HashRef, lazy => 1, default => sub { { key => 'value' } }, traits => [qw(LazyInflator)] );
has defaulthash => ( is => 'rw', isa => HashRef, default => sub { { key => 'value' } }, traits => [qw(LazyInflator)] );

package main;

use JSON;
use Test::Exception;

for(1..2) {
    my $t = Test->new( hash => q({"foo":"bar"}) );
    my $meta = $t->meta;
    {
        my $attr = $meta->get_attribute('hash');

        ok($attr->has_value($t), 'Attribute has value');
        is($attr->get_raw_value($t), q({"foo":"bar"}), 'Raw value is raw');
        is_deeply($attr->get_value($t), { foo => 'bar' }, 'Value has been inflated');
        is_deeply($attr->get_value($t), { foo => 'bar' }, 'Value has not been inflated again');

        $t = Test->new( hash => q({"foo":"bar"}) );
        is_deeply($t->hash, { foo => 'bar' }, 'Value has been inflated through accessor');
    }
    
    {
        my $attr = $meta->get_attribute('lazyhash');
        ok(!$attr->has_value($t), 'Attribute has no value');
        is($attr->get_raw_value($t), undef, 'Raw value is undef');
        is_deeply($attr->get_value($t), { key => 'value' }, 'get_value calls builder');
        
        $t = Test->new;
        is_deeply($t->lazyhash, { key => 'value' }, 'Builder works on accessor');
        
        $t = Test->new( lazyhash => q({"foo":"bar"}) );
        is_deeply($t->lazyhash, { foo => 'bar' }, 'Value has been inflated through accessor');
    }
    
    Test->meta->make_immutable;
}

done_testing;