package Test;

use Moose;
use DateTime;

use MooseX::Attribute::Deflator;

deflate 'DateTime', via { $_->epoch };
inflate 'DateTime', via { DateTime->from_epoch( epoch => $_ ) };

no MooseX::Attribute::Deflator;

use MooseX::Attribute::Deflator::Moose;

has now => ( is => 'rw', 
           isa => 'DateTime', 
           default => sub { DateTime->now }, 
           traits => ['Deflator'] );

has hash => ( is => 'rw', 
              isa => 'HashRef', 
              default => sub { { foo => 'bar' } }, 
              traits => ['Deflator'] );

package main;

use Test::More;

my $obj = Test->new;

{
    my $attr = $obj->meta->get_attribute('now');
    my $deflated = $attr->deflate($obj);
    like($deflated, qr/^\d+$/);

    my $inflated = $attr->inflate($obj, $deflated);
    isa_ok($inflated, 'DateTime');
}

{
    my $attr = $obj->meta->get_attribute('hash');
    my $deflated = $attr->deflate($obj);
    is($deflated, '{"foo":"bar"}');

    my $inflated = $attr->inflate($obj, $deflated);
    is_deeply($inflated, {foo => 'bar'})
}

  package LazyInflator;

  use Moose;
  use MooseX::Attribute::LazyInflator;
  use MooseX::Attribute::Deflator::Moose;

  has hash => ( is => 'rw', 
               isa => 'HashRef',
               traits => ['LazyInflator'] );

  package main;
  
  $obj = LazyInflator->new( hash => '{"foo":"bar"}' );
  # Attribute 'hash' is being inflated on access
  is_deeply($obj->hash, { foo => 'bar' });

done_testing;