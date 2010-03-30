package MooseX::Attribute::Deflator::Registry;

use Moose;
use Moose::Util::TypeConstraints;
my $REGISTRY = Moose::Util::TypeConstraints->get_type_constraint_registry;
no Moose::Util::TypeConstraints;

has deflators => ( 
	traits => ['Hash'],
	is => 'rw', 
	isa => 'HashRef[CodeRef]', 
	default    => sub { {} },
    handles    => { 
		has_deflator => 'get', 
		get_deflator => 'get', 
		set_deflator => 'set', 
		find_deflator => 'get'
	}
);

has inflators => ( 
	traits => ['Hash'],
	is => 'rw', 
	isa => 'HashRef[CodeRef]', 
	default    => sub { {} },
    handles    => { 
		has_inflator => 'get', 
		get_inflator => 'get', 
		set_inflator => 'set', 
		find_inflator => 'get'
	}
);

sub add_deflator {
	my ($self, $type_name, $via) = @_;
	unless( $type_name && $REGISTRY->find_type_constraint($type_name) ) {
		#Moose->throw_error('Could not find type constraint ' . $type_name);
	}
	$self->set_deflator($type_name, $via);
}

sub add_inflator {
	my ($self, $type_name, $via) = @_;
	unless( $type_name && $REGISTRY->find_type_constraint($type_name) ) {
		#Moose->throw_error('Could not find type constraint ' . $type_name);
	}
	$self->set_inflator($type_name, $via);
}

1;