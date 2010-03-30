package MooseX::Attribute::Deflator::Meta::Role::Attribute;

# ABSTRACT: Attribute meta role to support deflation
use Moose::Role;
use MooseX::Attribute::Deflator;
my $REGISTRY = MooseX::Attribute::Deflator->get_registry;
no MooseX::Attribute::Deflator;

foreach my $m (qw( deflator inflator)) {
    my $get = 'get_' . $m;
    ( my $action = $m ) =~ s/or/e/;
    __PACKAGE__->meta->add_method(
        $action => sub {
            my ( $self, $obj, $value, $constraint, @rest ) = @_;
            $value ||= $self->get_value($obj);
            $constraint ||= $self->type_constraint;
            ( my $name = $constraint->name ) =~ s/\[.*\]/\[\]/;
            if ( my $via = $REGISTRY->$get($name) ) {
                return $via->(
                    $obj, $constraint, sub { $self->$action( $obj, @_ ) }, @rest
                ) for ($value);
            }
            else {
                return $self->$action( $obj, $value, $constraint->parent,
                    @rest )
                  if ( $constraint->has_parent );
                Moose->throw_error( "Cannot $action " . $self->name );
            }
        }
    );

    __PACKAGE__->meta->add_method(
        'has_' . $m => sub {
            return $REGISTRY->$get( shift->type_constraint->name );
        }
    );
}

1;

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
               traits => ['MooseX::Attribute::Deflator::Meta::Role::Attribute'] );

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

=back
