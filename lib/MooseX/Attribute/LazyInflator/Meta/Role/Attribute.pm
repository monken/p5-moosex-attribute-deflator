package MooseX::Attribute::LazyInflator::Meta::Role::Attribute;

# ABSTRACT: Lazy inflate attributes
use Moose::Role;
use strict;
use warnings;
with 'MooseX::Attribute::Deflator::Meta::Role::Attribute';

override verify_against_type_constraint => sub {
    my ($self, $value, undef, $instance) = @_;
    return 1 if(!$self->is_inflated($instance));
    super;
};

before get_value => sub {
    my ($self, $instance) = @_;
    return if(!$self->has_value($instance) || $self->is_inflated($instance));
    $self->set_value($instance, $self->inflate($instance, $self->get_raw_value($instance)));
};

sub is_inflated {
    my ($self, $instance, $value) = @_;
    return $instance->_inflated_attributes->{$self->name} = $value
        if(defined $value);
    if($instance->_inflated_attributes->{$self->name}) {
        return 1;
    } else {
        return 
            $self->has_type_constraint 
            && $self->type_constraint->check($self->get_raw_value($instance))
            && ++$instance->_inflated_attributes->{$self->name}
    }
}

use MooseX::Attribute::LazyInflator::Meta::Role::Method::Accessor;
sub accessor_metaclass { 'MooseX::Attribute::LazyInflator::Meta::Role::Method::Accessor' }


1;

__END__

=head1 SYNOPSIS

  package Test;

  use Moose;
  use MooseX::Attribute::LazyInflator;
  # Load default deflators and inflators
  use MooseX::Attribute::Deflator::Moose;

  has hash => ( is => 'rw', 
               isa => 'HashRef',
               traits => ['LazyInflator'] );

  package main;
  
  my $obj = Test->new( hash => '{"foo":"bar"}' );
  # Attribute 'hash' is being inflated to a HashRef on access
  $obj->hash;

=head1 ROLES

This role consumes L<MooseX::Attribute::Deflator::Meta::Role::Attribute>.

=head1 METHODS

=over 8

=item B<is_inflated( $intance )>

Returns a true value if the value of the attribute passes the type contraint
or has been inflated.

=item before B<get_value>

The attribute's value is being inflated and set if it has a value and hasn't been inflated yet.

=item override B<verify_against_type_constraint>

Will return true if the attribute hasn't been inflated yet.

=back

=head1 FUNCTIONS

=over 8

=item B<accessor_metaclass>

The accessor metaclass is set to L<MooseX::Attribute::LazyInflator::Meta::Role::Method::Accessor>.

=back