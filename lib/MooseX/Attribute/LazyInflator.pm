package MooseX::Attribute::LazyInflator;
# ABSTRACT: Deflates and inflates Moose attributes to and from a string

use Moose();
use MooseX::Attribute::Deflator ();
use Moose::Exporter;
use Moose::Util ();

Moose::Exporter->setup_import_methods;

sub init_meta {
      shift;
      my %args = @_;

      Moose->init_meta(%args);

      Moose::Util::MetaRole::apply_metaroles(
          for             => $args{for_class},
          class_metaroles => {
              constructor => ['MooseX::Attribute::LazyInflator::Meta::Role::Method::Constructor'],
          },
      );

      Moose::Util::apply_all_roles($args{for_class}, 'MooseX::Attribute::LazyInflator::Role::Class');

      return $args{for_class}->meta;
}

Moose::Util::_create_alias('Attribute', 'LazyInflator', 1, 'MooseX::Attribute::LazyInflator::Meta::Role::Attribute');



1;

__END__


=head1 SYNOPSIS

  package Test;

  use Moose;
  use MooseX::Attribute::LazyInflator;
  # Load default deflators and inflators
  use MooseX::Attribute::Deflator::Moose;

  has hash => ( is => 'rw', 
               isa => 'HashRef',
               traits => ['LazyInflator'] );

  package main;
  
  my $obj = Test->new( hash => '{"foo":"bar"}' );
  # Attribute 'hash' is being inflated to a HashRef on access
  $obj->hash;
  
=head1 DESCRIPTION

Using C<coerce> will inflate an object on construction even if it is not needed.
This has the advantage, that type constraints are being called but on the other hand
it is rather slow.

This module will defer object inflation and constraint validation until it is first accessed. 
Furthermore the advantages of C<inflate> apply as well.

=head1 SEE ALSO

=over 8

=item L<MooseX::Attribute::LazyInflator::Role::Class>

=item MooseX::Attribute::LazyInflator::Meta::Role::Method::Accessor>

=item L<MooseX::Attribute::LazyInflator::Meta::Role::Method::Constructor>

=item L<MooseX::Attribute::Deflator/inflate>

=back