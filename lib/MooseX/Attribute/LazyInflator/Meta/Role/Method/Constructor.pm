package MooseX::Attribute::LazyInflator::Meta::Role::Method::Constructor;

# ABSTRACT: Lazy inflate attributes
use Moose::Role;
use strict;
use warnings;

override _generate_type_coercion => sub {
    my $self = shift;
    return $self->_generate_skip_coercion_and_constraint($_[0], super);
};

override _generate_type_constraint_check => sub {
    my $self = shift;
    return $self->_generate_skip_coercion_and_constraint($_[0], super);
};

sub _generate_skip_coercion_and_constraint {
    my ($self, $attr, $code) = @_;
    if($attr->does('MooseX::Attribute::LazyInflator::Meta::Role::Attribute')) {
        return '';
    }
    return $code;
}

1;

__END__

=head1 METHODS

=over 8

=item override B<_generate_type_coercion>

=item override B<_generate_type_constraint_check>

=item B<_generate_skip_coercion_and_constraint>

Coercion and type constraint verification is not processed if the
attribute has not been inflated yet.

=back
