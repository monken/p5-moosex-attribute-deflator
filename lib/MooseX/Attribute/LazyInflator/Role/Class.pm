package MooseX::Attribute::LazyInflator::Role::Class;

# ABSTRACT: Lazy inflate attributes
use Moose::Role;
use strict;
use warnings;

has _inflated_attributes => ( is => 'rw', isa => 'HashRef', lazy => 1, default => sub {{}} );


1;

__END__

=head1 ATTRIBUTES

=over 8

=item B<_inflated_attributes>

This attributes keeps a HashRef of inflated attributes.

=back