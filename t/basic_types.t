use Test::More;
use strict;
use warnings;

package Test;

use Moose;
use JSON;
use DateTime;

use MooseX::Attribute::Deflator::Moose;
use MooseX::Attribute::Deflator;


deflate 'DateTime', via { $_->epoch };
inflate 'DateTime', via { DateTime->from_epoch( epoch => $_ ) };





has hashref => ( is => 'rw', isa => 'HashRef', traits => ['Deflator'] );

has hashrefarray => ( is => 'rw', isa => 'HashRef[ArrayRef[HashRef]]', traits => ['Deflator'] );

has datetime => ( is => 'rw', isa => 'DateTime', required => 1, default => sub { DateTime->now }, traits => ['Deflator'] );

has datetimearrayref => ( is => 'rw', isa => 'ArrayRef[DateTime]', required => 1, default => sub { [DateTime->now, DateTime->now->add(hours => 1) ] }, traits => ['Deflator'] );

has scalarint => ( is => 'rw', isa => 'ScalarRef[Int]', required => 1, default => sub { \1 }, traits => ['Deflator'] );

has bool => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Deflator'] );

package main;

my $obj = Test->new( hashref => { foo => 'bar' }, hashrefarray => { foo => [{ foo => 'bar'}] } );
    

{
    is_deeply( $obj->meta->get_attribute('hashref')->get_value($obj), { foo => 'bar' } );
    is( $obj->meta->get_attribute('hashref')->deflate($obj), '{"foo":"bar"}' );
    is_deeply( $obj->meta->get_attribute('hashref')->inflate($obj, '{"foo":"bar"}'), {foo => 'bar'} );
    is( $obj->meta->get_attribute('hashrefarray')->deflate($obj), '{"foo":"[\"{\\\\\"foo\\\\\":\\\\\"bar\\\\\"}\"]"}' );
    is_deeply( $obj->meta->get_attribute('hashrefarray')->inflate($obj, '{"foo":"[\"{\\\\\"foo\\\\\":\\\\\"bar\\\\\"}\"]"}'), 
        { foo => [{ foo => 'bar'}] } );    
}

{
    isa_ok($obj->datetime, 'DateTime');
    my $epoch = $obj->meta->get_attribute('datetime')->deflate($obj);
    like( $epoch, qr/^\d+$/, 'deflated to epoch time');
    is( $obj->meta->get_attribute('datetime')->inflate($obj, $epoch), $obj->datetime, 'inflates to same time');
    isa_ok($obj->datetime, 'DateTime');
}

{
    isa_ok($obj->datetimearrayref->[0], 'DateTime');
    my $times = $obj->meta->get_attribute('datetimearrayref')->deflate($obj);
    isa_ok($obj->datetimearrayref->[0], 'DateTime');
    like( $times, qr/^\[\d+,\d+\]$/, 'deflated to json with epoch time');
    my $inflated = $obj->meta->get_attribute('datetimearrayref')->inflate($obj, $times);
    is_deeply( $obj->meta->get_attribute('datetimearrayref')->inflate($obj, $times), $obj->datetimearrayref, 'inflates to same time');
}

{
    is(ref $obj->scalarint, 'SCALAR', 'scalar ref attribute');
    my $num = $obj->meta->get_attribute('scalarint')->deflate($obj);
    is($num, 1, 'deflates to int');
    is_deeply($obj->meta->get_attribute('scalarint')->inflate($obj, 1), \1, 'inflates to scalarref');

}

{
    ok($obj->bool, 'bool is true');
    my $bool = $obj->meta->get_attribute('bool')->deflate($obj);
    ok($bool, 'deflates to a true value');
    is_deeply($obj->meta->get_attribute('bool')->inflate($obj, 1), 1, 'inflates to a true value');

}


done_testing;