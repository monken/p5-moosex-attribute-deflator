package MooseX::Attribute::Deflator::Meta::Role::Attribute;

# ABSTRACT: Attribute meta role to support deflation
use Moose::Role;
use Try::Tiny;
use Eval::Closure;
use MooseX::Attribute::Deflator;
my $REGISTRY = MooseX::Attribute::Deflator->get_registry;
no MooseX::Attribute::Deflator;

has is_deflator_inlined => ( is => 'rw', isa => 'Bool', default => 0 );
has is_inflator_inlined => ( is => 'rw', isa => 'Bool', default => 0 );

sub _inline_deflator {
    my $self = shift;
    my $role = Moose::Meta::Role->create_anon_role;
    foreach my $type (qw(deflator inflator)) {
        my $find
            = $type eq 'deflator'
            ? 'find_inlined_deflator'
            : 'find_inlined_inflator';
        my $method      = $type eq 'deflator' ? 'deflate' : 'inflate';
        my $tc          = $self->type_constraint;
        my $slot_access = $self->_inline_instance_get('$_[1]');
        my $deflator    = $tc
            ? do {
            my $inline = eval { $REGISTRY->$find($tc) } or next;
            $inline->( $tc, $self, sub { $REGISTRY->$find(@_) } );
            }
            : $slot_access;
        my $has_value  = $self->_inline_instance_has('$_[1]');
        my @check_lazy = $self->_inline_check_lazy(
            '$_[1]',          '$type_constraint',
            '$type_coercion', '$type_message',
        );
        my @code = ('sub {');
        if ( $type eq 'deflator' ) {
            push( @code,
                @check_lazy,
                $self->is_required
                ? ""
                : "return undef unless($has_value);",
                'my $value = ' . $slot_access . ';',
            );
        }
        else {
            push( @code, 'my $value = $_[2];' );
        }
        $role->add_method(
            $method => eval_closure(
                environment => $self->_eval_environment,
                source      => join( "\n", @code, $deflator, '}' )
            )
        );
        $type eq 'deflator'
            ? $self->is_deflator_inlined(1)
            : $self->is_inflator_inlined(1);
    }
    Moose::Util::apply_all_roles( $self, $role );
}

sub deflate {
    my ( $self, $obj, $value, $constraint, @rest ) = @_;
    $value ||= $self->get_value($obj)
        if ( $self->has_value($obj) || $self->is_required );
    return undef unless ( defined $value );
    $constraint ||= $self->type_constraint;
    return $value unless ($constraint);
    return $value
        unless ( my $via = $REGISTRY->find_deflator($constraint) );
    my $return;
    try {
        $return = $via->(
            $self, $constraint, sub { $self->deflate( $obj, @_ ) },
            $obj, @rest
        ) for ($value);
    }
    catch {
        die
            qq{Failed to deflate value "$value" (${\($constraint->name)}): $_};
    };
    return $return;
}

sub inflate {
    my ( $self, $obj, $value, $constraint, @rest ) = @_;
    return undef unless ( defined $value );
    $constraint ||= $self->type_constraint;
    return $value unless ($constraint);
    return $value
        unless ( my $via = $REGISTRY->find_inflator($constraint) );
    my $return;
    try {
        $return = $via->(
            $self, $constraint, sub { $self->inflate( $obj, @_ ) },
            $obj, @rest
        ) for ($value);
    }
    catch {
        die
            qq{Failed to inflate value "$value" (${\($constraint->name)}): $_};
    };
    return $return;
}

sub has_deflator {
    my $self = shift;
    return unless ( $self->has_type_constraint );
    $REGISTRY->find_deflator( $self->type_constraint, 'norecurse' );
}

sub has_inflator {
    my $self = shift;
    return unless ( $self->has_type_constraint );
    $REGISTRY->find_inflator( $self->type_constraint, 'norecurse' );
}

after install_accessors => \&_inline_deflator if ( $Moose::VERSION >= 1.9 );

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

  has now => ( is => 'rw', 
               isa => 'DateTime', 
               required => 1, 
               default => sub { DateTime->now }, 
               traits => ['Deflator'] );

  package main;
  
  my $obj = Test->new;
  my $attr = $obj->meta->get_attribute('now');
  
  my $deflated = $attr->deflate($obj);
  # $deflated is now a number
  
  my inflated = $attr->inflate($obj, $deflated);
  # $inflated is now a DateTime object
  
  

=head1 METHODS

These two methods work basically the same. They look up the type constraint 
which is associated with the attribute and try to find an appropriate
deflator/inflator. If there is no deflator/inflator for the exact type
constraint, the method will bubble up the type constraint hierarchy
until it finds one.

=over 4

=item B<< $attr->deflate($instance) >>

Returns the deflated value of the attribute. It does not change the value
of the attribute.

=item B<< $attr->inflate($instance, $string) >>

Inflates a string C<$string>. This method does not set the value of
the attribute to the inflated value.

=item B<< $attr->has_inflator >>
=item B<< $attr->has_deflator >>

=back
