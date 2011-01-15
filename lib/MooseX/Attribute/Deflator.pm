package MooseX::Attribute::Deflator;
# ABSTRACT: Deflates and inflates Moose attributes to and from a string

use strict;
use warnings;
use Moose::Exporter;
use MooseX::Attribute::Deflator::Registry;
use Moose::Util qw();

sub via (&) { $_[0] }
sub inline (&) { $_[0] }

Moose::Exporter->setup_import_methods(
    as_is => [
        qw( deflate inflate via inline )
    ],
);

my $REGISTRY = MooseX::Attribute::Deflator::Registry->new;

sub get_registry { $REGISTRY }

sub deflate {
	$REGISTRY->add_deflator(@_);
}

sub inflate {
	$REGISTRY->add_inflator(@_);
}


Moose::Util::_create_alias('Attribute', 'Deflator', 1, 'MooseX::Attribute::Deflator::Meta::Role::Attribute');

1;

__END__

=head1 SYNOPSIS

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

 done_testing;

=head1 DESCRIPTION

This module consists of a a registry (L<MooseX::Attribute::Deflator::Registry>) an attribute trait L<MooseX::Attribute::Deflator::Meta::Role::Attribute> and predefined deflators and inflators
for Moose L<MooseX::Attribute::Deflator::Moose> and MooseX::Types::Strutured L<MooseX::Attribute::Deflator::Structured>.
This class is just sugar to set the inflators and deflators.

Unlike C<coerce>, you don't need to create a deflator and inflator for every type. Instead this module
will bubble up the type hierarchy and use the first deflator or inflator it finds.

This comes at a cost: B<Union types are not supported>.

=head1 FUNCTIONS

=over 4

=item B<< deflate >>

=item B<< inflate >>

 deflate 'DateTime', via { $_->epoch };
 
 inflate 'DateTime', via { DateTime->from_epoch( epoch => $_ ) };
    
Defines a deflator or inflator for a given type constraint. This can also be
a type constraint defined via L<MooseX::Types> and parameterized types.

The function supplied to C<via> is called with C<$_> set to the attribute's value
and with the following arguments:

=over 8

=item C<$attr>

The attribute on which this deflator/inflator has been called

=item C<$constraint>

The type constraint attached to the attribute

=item C<< $deflate/$inflate >>

A code reference to the deflate or inflate function. E.g. this is handy if you want
to call the type's parent's parent inflate or deflate method:

 deflate 'MySubSubType', via {
    my ($attr, $constraint, $deflate) = @_;
    return $deflate->($_, $constraint->parent->parent);
 };

=item C<$instance>

The object instance on which this deflator/inflator has been called


=item C<@_>

Any other arguments added to L<MooseX::Attribute::Deflator::Meta::Role::Attribute/inflate>
or L<MooseX::Attribute::Deflator::Meta::Role::Attribute/deflate>.

=back

=back