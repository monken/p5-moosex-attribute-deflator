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
