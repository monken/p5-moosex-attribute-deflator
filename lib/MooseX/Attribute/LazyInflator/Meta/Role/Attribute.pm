package MooseX::Attribute::LazyInflator::Meta::Role::Attribute;

# ABSTRACT: Lazy inflate attributes
use strict;
use warnings;
use Moose::Role;

with 'MooseX::Attribute::Deflator::Meta::Role::Attribute';

override verify_against_type_constraint => sub {
    my ( $self, $value, undef, $instance ) = @_;
    return $value if ( !$self->is_inflated($instance) );
    return super();
};

before get_value => sub {
    my ( $self, $instance ) = @_;
    return if ( !$self->has_value($instance) || $self->is_inflated($instance) );
    $self->is_inflated($instance);
    my $value = $self->inflate( $instance, $self->get_raw_value($instance) );
    $value = $self->type_constraint->coerce($value)
      if ( $self->should_coerce && $self->type_constraint->has_coercion );
    $self->verify_against_type_constraint( $value,
        instance => $instance );
    $self->set_raw_value( $instance, $value );
};

override _inline_get_value => sub {
    my ( $self, $instance, $tc, $tc_obj ) = @_;
    $tc     ||= '$type_constraint';
    $tc_obj ||= '$type_constraint_obj';
    my $slot_exists = $self->_inline_instance_has($instance);
    my @code        = (
        "if($slot_exists && !(",
        $self->_inline_instance_is_inflated( $instance, $tc, $tc_obj ),
        ")) {",
        'my $inflated = '
          . "\$attr->inflate($instance, "
          . $self->_inline_instance_get($instance) . ");",
        $self->has_type_constraint
        ? (
            $self->_inline_check_coercion( '$inflated', $tc, $tc_obj, 1 ),
            $self->_inline_check_constraint( '$inflated', $tc, $tc_obj, 1 )
          )
        : (),
        $self->_inline_init_slot( $instance, '$inflated' ),
        "}"
    );
    push @code, super();
    return @code;
};

sub is_inflated {
    my ( $self, $instance, $value ) = @_;
    return $instance->_inflated_attributes->{ $self->name } = $value
      if ( defined $value );
    if ( $instance->_inflated_attributes->{ $self->name } ) {
        return 1;
    }
    else {
        my $value = $self->get_raw_value($instance);
        $value = $self->type_constraint->coerce($value)
          if ( $self->should_coerce && $self->type_constraint->has_coercion );
        return
             $self->has_type_constraint
          && $self->type_constraint->check($value)
          && ++$instance->_inflated_attributes->{ $self->name };
    }
}

sub _inline_instance_is_inflated {
    my ( $self, $instance, $tc, $tc_obj ) = @_;
    my @code =
      (     $instance
          . '->{_inflated_attributes}->{"'
          . quotemeta( $self->name )
          . '"}' );
    return @code if ( !$self->has_type_constraint );
    my $value = $self->_inline_instance_get($instance);
    my $coerce =
        $self->should_coerce && $self->type_constraint->has_coercion
      ? $tc_obj . '->coerce(' . $value . ')'
      : $value;
    push @code,
      (     ' || (' 
          . $tc . '->('
          . $coerce
          . ') && ++'
          . $instance
          . '->{_inflated_attributes}->{"'
          . quotemeta( $self->name )
          . '"})' );
    return @code;
}

override _inline_tc_code => sub {
    #my $self = shift;
    return ('');
};

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
