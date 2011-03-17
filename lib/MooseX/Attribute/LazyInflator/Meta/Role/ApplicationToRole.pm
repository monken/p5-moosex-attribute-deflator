package MooseX::Attribute::LazyInflator::Meta::Role::ApplicationToRole;
use Moose::Role;
use MooseX::Attribute::LazyInflator::Role::Class;

around apply => sub {
    my $orig  = shift;
    my $self  = shift;
    my $role  = shift;
    my $class = shift;
    $class =
      Moose::Util::MetaRole::apply_metaroles(
        for            => $class,
        role_metaroles => {
            application_to_class => [
'MooseX::Attribute::LazyInflator::Meta::Role::ApplicationToClass'
            ],
        } );
    $self->$orig( $role, $class );
};

1;
