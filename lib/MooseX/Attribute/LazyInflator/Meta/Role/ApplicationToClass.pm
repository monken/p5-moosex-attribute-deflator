package MooseX::Attribute::LazyInflator::Meta::Role::ApplicationToClass;
use Moose::Role;
use MooseX::Attribute::LazyInflator::Role::Class;

around apply => sub {
    my $orig  = shift;
    my $self  = shift;
    my $role  = shift;
    my $class = shift;
    $class =
      Moose::Util::MetaRole::apply_metaroles(
        for             => $class,
        class_metaroles => {
            constructor => [
'MooseX::Attribute::LazyInflator::Meta::Role::Method::Constructor'
            ],
        } ) if ( Moose->VERSION < 1.9900 );

    Moose::Util::MetaRole::apply_base_class_roles(
                       for   => $class->name,
                       roles => ['MooseX::Attribute::LazyInflator::Role::Class']
    );

    $self->$orig( $role, $class );
};

1;
