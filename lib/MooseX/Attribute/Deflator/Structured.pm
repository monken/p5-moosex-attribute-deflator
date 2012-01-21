package MooseX::Attribute::Deflator::Structured;

# ABSTRACT: Deflators for MooseX::Types::Structured

use MooseX::Attribute::Deflator;

deflate 'MooseX::Types::Structured::Optional[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    return $deflate->( $_, $constraint->type_parameter );
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parameter = $deflators->( $constraint->type_parameter );
    return $parameter->( $constraint->type_parameter, @_ );
};

inflate 'MooseX::Types::Structured::Optional[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    return $inflate->( $_, $constraint->type_parameter );
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parameter = $deflators->( $constraint->type_parameter );
    return $parameter->( $constraint->type_parameter, @_ );
};

deflate 'MooseX::Types::Structured::Map[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    my $value       = {%$_};
    my $constraints = $constraint->type_constraints;
    while ( my ( $k, $v ) = each %$value ) {
        $value->{$k} = $deflate->( $value->{$k}, $constraints->[1] );
    }
    return $deflate->( $value, $constraint->parent );
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parent    = $deflators->( $constraint->parent );
    my $parameter = $deflators->( $constraint->type_constraints->[1] );
    return join( "\n",
        '$value = {%$value};',
        'while ( my ( $k, $v ) = each %$value ) {',
        '$value->{$k} = do {',
        '    my $value = $value->{$k};',
        '    $value = do {',
        $parameter->( $constraint->type_constraints->[1], @_ ),
        '    };',
        '  };',
        '}',
        $parent->( $constraint->parent, @_ ),
    );
};

inflate 'MooseX::Types::Structured::Map[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    my $value = $inflate->( $_, $constraint->parent );
    my $constraints = $constraint->type_constraints;
    while ( my ( $k, $v ) = each %$value ) {
        $value->{$k} = $inflate->( $value->{$k}, $constraints->[1] );
    }
    return $value;
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parent = $deflators->( $constraint->parent );
    my $parameter
        = $deflators->( $constraint->type_constraints->[1] );
    return join( "\n",
        '$value = do {',
        $parent->( $constraint->parent, @_ ),
        ' };',
        'while ( my ( $k, $v ) = each %$value ) {',
        '  $value->{$k} = do {',
        '    my $value = $value->{$k};',
        '    $value = do {',
        $parameter->( $constraint->type_constraints->[1], @_ ),
        '    };',
        '  };',
        '}',
        '$value',
    );
};

deflate 'MooseX::Types::Structured::Dict[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    my %constraints = @{ $constraint->type_constraints };
    my $value       = {%$_};
    while ( my ( $k, $v ) = each %$value ) {
        $value->{$k} = $deflate->( $value->{$k}, $constraints{$k} );
    }
    return $deflate->( $value, $constraint->parent );
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parent      = $deflators->( $constraint->parent );
    my %constraints = @{ $constraint->type_constraints };
    my @map         = 'my $dict;';
    while ( my ( $k, $v ) = each %constraints ) {
        push( @map,
            '$dict->{' . quotemeta($k) . '} = sub { ',
            'my $value = shift;',
            $deflators->($v)->( $v, @_ ), ' };' );
    }
    return join( "\n",
        @map,
        '$value = {%$value};',
        'while ( my ( $k, $v ) = each %$value ) {',
        '$value->{$k} = do {',
        '    my $value = $value->{$k};',
        '    $value = $dict->{$k}->($value);',
        '  };',
        '}',
        $parent->( $constraint->parent, @_ ),
    );
};

inflate 'MooseX::Types::Structured::Dict[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    my %constraints = @{ $constraint->type_constraints };
    my $value = $inflate->( $_, $constraint->parent );
    while ( my ( $k, $v ) = each %$value ) {
        $value->{$k} = $inflate->( $value->{$k}, $constraints{$k} );
    }
    return $value;
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parent      = $deflators->( $constraint->parent );
    my %constraints = @{ $constraint->type_constraints };
    my @map         = 'my $dict;';
    while ( my ( $k, $v ) = each %constraints ) {
        push( @map,
            '$dict->{' . quotemeta($k) . '} = sub { ',
            'my $value = shift;',
            $deflators->($v)->( $v, @_ ), ' };' );
    }
    return join( "\n",
        @map,
        '$value = do {',
        $parent->( $constraint->parent, @_ ),
        ' };',
        'while ( my ( $k, $v ) = each %$value ) {',
        '$value->{$k} = do {',
        '    my $value = $value->{$k};',
        '    $value = $dict->{$k}->($value);',
        '  };',
        '}',
        '$value',
    );
};;

deflate 'MooseX::Types::Structured::Tuple[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    my @constraints = @{ $constraint->type_constraints };
    my $value       = [@$_];
    for ( my $i = 0; $i < @$value; $i++ ) {
        $value->[$i] = $deflate->( $value->[$i],
            $constraints[$i] || $constraints[-1] );
    }
    return $deflate->( $value, $constraint->parent );
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parent      = $deflators->( $constraint->parent );
    my @constraints = @{ $constraint->type_constraints };
    my @map         = 'my $tuple = [];';
    foreach my $tc (@constraints) {
        push( @map,
            'push(@$tuple, sub {',
            'my $value = shift;',
            $deflators->($tc)->( $tc, @_ ), ' });' );
    }
    return join( "\n",
        @map,
        '$value = [@$value];',
        'for ( my $i = 0; $i < @$value; $i++ ) {',
        '$value->[$i] = do {',
        '    my $value = $value->[$i];',
        '    $value = ($tuple->[$i] || $tuple->[-1])->($value);',
        '  };',
        '}',
        $parent->( $constraint->parent, @_ ),
    );
};

inflate 'MooseX::Types::Structured::Tuple[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    my @constraints = @{ $constraint->type_constraints };
    my $value = $inflate->( $_, $constraint->parent );
    for ( my $i = 0; $i < @$value; $i++ ) {
        $value->[$i] = $inflate->( $value->[$i],
            $constraints[$i] || $constraints[-1] );
    }
    return $value;
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parent      = $deflators->( $constraint->parent );
    my @constraints = @{ $constraint->type_constraints };
    my @map         = 'my $tuple = [];';
    foreach my $tc (@constraints) {
        push( @map,
            'push(@$tuple, sub {',
            'my $value = shift;',
            $deflators->($tc)->( $tc, @_ ), ' });' );
    }
    return join( "\n",
        @map,
        '$value = do {',
        $parent->( $constraint->parent, @_ ),
        ' };',
        'for ( my $i = 0; $i < @$value; $i++ ) {',
        '$value->[$i] = do {',
        '    my $value = $value->[$i];',
        '    $value = ($tuple->[$i] || $tuple->[-1])->($value);',
        '  };',
        '}',
        '$value',
    );
};

1;

__END__

=head1 SYNOPSIS

  use MooseX::Attribute::Deflator::Structured;
  
=head1 DESCRIPTION

This module registers sane type deflators and inflators for L<MooseX::Types::Structured>.
