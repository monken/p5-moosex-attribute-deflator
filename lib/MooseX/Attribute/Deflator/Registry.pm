package MooseX::Attribute::Deflator::Registry;

# ABSTRACT: Registry class for attribute deflators
use Moose;

has deflators => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[CodeRef]',
    default => sub { {} },
    handles => {
        has_deflator  => 'get',
        get_deflator  => 'get',
        set_deflator  => 'set',
        _add_deflator => 'set',
    }
);

has inlined_deflators => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[CodeRef]',
    default => sub { {} },
    handles => {
        has_inlined_deflator  => 'get',
        get_inlined_deflator  => 'get',
        set_inlined_deflator  => 'set',
        _add_inlined_deflator => 'set',
    }
);

has inflators => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[CodeRef]',
    default => sub { {} },
    handles => {
        has_inflator  => 'get',
        get_inflator  => 'get',
        set_inflator  => 'set',
        _add_inflator => 'set',
    }
);

has inlined_inflators => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[CodeRef]',
    default => sub { {} },
    handles => {
        has_inlined_inflator  => 'get',
        get_inlined_inflator  => 'get',
        set_inlined_inflator  => 'set',
        _add_inlined_inflator => 'set',
    }
);

sub add_deflator {
    my ( $self, $name, $deflator, $inlined ) = @_;
    $self->_add_inlined_deflator( $name, $inlined ) if ($inlined);
    return $self->_add_deflator( $name, $deflator );
}

sub find_deflator {
    my ( $self, $constraint, $norecurse ) = @_;
    ( my $name = $constraint->name ) =~ s/\[.*\]/\[\]/;
    my $sub = $self->get_deflator($name);
    return undef if ( !$sub && $norecurse );
    if ( !$sub && $constraint->has_parent ) {
        $sub = $self->find_deflator( $constraint->parent );
        $self->set_deflator( $name, $sub ) if ($sub);
    }
    return $sub;
}

sub find_inlined_deflator {
    my ( $self, $constraint, $norecurse ) = @_;
    ( my $name = $constraint->name ) =~ s/\[.*\]/\[\]/;
    my $sub = $self->get_deflator($name);
    return undef if ( !$sub && $norecurse );
    if ( !$sub && $constraint->has_parent ) {
        $sub = $self->find_inlined_deflator( $constraint->parent );
        $self->set_inlined_deflator( $name, $sub ) if ($sub);
    }
    return $self->get_inlined_deflator($name)
        || die "Could not find inlined deflator for $name";
}

sub add_inflator {
    my ( $self, $name, $inflator, $inlined ) = @_;
    $self->_add_inlined_inflator( $name, $inlined ) if ($inlined);
    return $self->_add_inflator( $name, $inflator );
}

sub find_inflator {
    my ( $self, $constraint, $norecurse ) = @_;
    ( my $name = $constraint->name ) =~ s/\[.*\]/\[\]/;
    my $sub = $self->get_inflator($name);
    return undef if ( !$sub && $norecurse );
    if ( !$sub && $constraint->has_parent ) {
        $sub = $self->find_inflator( $constraint->parent );
        $self->set_inflator( $name, $sub ) if ($sub);
    }
    return $sub;
}

sub find_inlined_inflator {
    my ( $self, $constraint, $norecurse ) = @_;
    ( my $name = $constraint->name ) =~ s/\[.*\]/\[\]/;
    my $sub = $self->get_inflator($name);
    return undef if ( !$sub && $norecurse );
    if ( !$sub && $constraint->has_parent ) {
        $sub = $self->find_inlined_inflator( $constraint->parent );
        $self->set_inlined_inflator( $name, $sub ) if ($sub);
    }
    return $self->get_inlined_inflator($name)
        || die "Could not find inlined inflator for $name";
}

1;

__END__

=head1 DESCRIPTION

This class contains a registry for deflator and inflator functions.

=head1 ATTRIBUTES

=over 4

=item B<< inflators ( isa => HashRef[CodeRef] ) >>

=item B<< deflators ( isa => HashRef[CodeRef] ) >>

=back

=head1 METHODS

=over 4

=item B<< add_inflator( $type_constraint, $coderef ) >>

=item B<< add_deflator( $type_constraint, $coderef ) >>

=item B<< set_inflator( $type_constraint, $coderef ) >>

=item B<< set_deflator( $type_constraint, $coderef ) >>

Add a inflator/deflator function for C<$type_constraint>. Existing functions
are overwritten.

=item B<< has_inflator( $type_constraint ) >>

=item B<< has_deflator( $type_constraint )  >>

Predicate methods.

=item B<< find_inflator( $type_constraint ) >>

=item B<< find_deflator( $type_constraint )  >>

Finds a suitable deflator/inflator by bubbling up the type hierarchy.

=back
