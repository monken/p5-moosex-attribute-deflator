package MooseX::Attribute::Deflator::Meta::Role::Attribute;

use Moose::Role;
use MooseX::Attribute::Deflator;
my $REGISTRY = MooseX::Attribute::Deflator->get_registry;
no MooseX::Attribute::Deflator;

sub has_deflator {
	my ($self) = @_;
	return$REGISTRY->get_deflator($self->type_constraint->name);
}

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Maxdepth = 2;

sub deflate {
	my ($self, $obj, $value, $constraint, @rest) = @_;
    $value ||= $self->get_value($obj);
    $constraint ||= $self->type_constraint;
    (my $name = $constraint->name) =~ s/\[.*\]/\[\]/;
    my $via = $REGISTRY->get_deflator($name);
    unless($via) {

        return $self->deflate($obj, $value, $constraint->parent, @rest) if($constraint->has_parent);
        
    
    }
	Moose->throw_error('Cannot deflate ' . $self->name) unless($via);
	return $via->($obj, $constraint, sub { $self->deflate($obj, @_) }, @rest ) for($value);
}


sub has_inflator {
	my ($self) = @_;
	return $REGISTRY->get_inflator($self->type_constraint->name);
}

sub inflate {
	my ($self, $obj, $value, $constraint, @rest) = @_;
    $value ||= $self->get_value($obj);
    $constraint ||= $self->type_constraint;
	(my $name = $constraint->name) =~ s/\[.*\]/\[\]/;
    my $via = $REGISTRY->get_inflator($name);

    unless($via) {
        return $self->inflate($obj, $value, $constraint->parent, @rest) if($constraint->has_parent);
    }
    Moose->throw_error('Cannot inflate ' . $self->name) unless($via);
    return $via->($obj, $constraint, sub { $self->inflate($obj, @_) }, @rest) for($value);
}

1;