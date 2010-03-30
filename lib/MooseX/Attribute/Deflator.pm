package MooseX::Attribute::Deflator;
# ABSTRACT: Deflates Moose attributes to a string

use strict;
use warnings;
use Moose::Exporter;
use MooseX::Attribute::Deflator::Registry;

sub via (&) { $_[0] }


Moose::Exporter->setup_import_methods(
    as_is => [
        qw( deflate inflate via )
    ],
);

my $REGISTRY = MooseX::Attribute::Deflator::Registry->new;

sub get_registry { $REGISTRY }

sub deflate {
	my ($type_name, $via) = @_;
	$REGISTRY->add_deflator($type_name, $via);
}



sub inflate {
	my ($type_name, $via) = @_;
	$REGISTRY->add_inflator($type_name, $via);
}



1;