package MooseX::Attribute::LazyInflator::Meta::Role::Method::Accessor;

# ABSTRACT: Lazy inflate attributes
use base 'Moose::Meta::Method::Accessor';
use strict;
use warnings;

sub _inline_check_lazy {
    my ( $self, $instance ) = @_;
    my $slot_exists = $self->_inline_has($instance);
    my $code = "if($slot_exists && !\$attr->is_inflated($instance)) {\n  ";
    $code .= "my \$inflated = \$attr->inflate($instance, " . $self->_inline_get($instance) . ");\n";
    $code .= $self->_inline_check_coercion("\$inflated") . "\n";
    $code .= $self->_inline_check_constraint("\$inflated") . "\n";
    $code .= $self->_inline_store( $instance, "\$inflated" ) . "\n";
    $code .= "}\n\n";
    $code .= $self->next::method($instance);
    return $code;
}

1;

__END__

=head1 INHERITANCE

This class is a base class of L<Moose::Meta::Method::Accessor>.

This is subject to change. As the name suggests, it should be role.

=head1 METHODS

=over 8

=item override B<_inline_check_lazy>

The attribute's value is being inflated and set if it has a value and hasn't been inflated yet.

=back
