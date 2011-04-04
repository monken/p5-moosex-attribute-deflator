package MooseX::Attribute::LazyInflator::Meta::Role::Role;
use Moose::Role;

sub composition_class_roles {
    'MooseX::Attribute::LazyInflator::Meta::Role::Composite'
}

no Moose::Role;

1;
