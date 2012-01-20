package MooseX::Attribute::Deflator::Moose;

# ABSTRACT: Deflators for Moose type constraints

use MooseX::Attribute::Deflator;
use JSON;

deflate 'HashRef', via { JSON::encode_json($_) },
    inline {'JSON::encode_json($value)'};
inflate 'HashRef', via { JSON::decode_json($_) },
    inline {'JSON::decode_json($value)'};

deflate 'ArrayRef', via { JSON::encode_json($_) },
    inline {'JSON::encode_json($value)'};
inflate 'ArrayRef', via { JSON::decode_json($_) },
    inline {'JSON::decode_json($value)'};

deflate 'ScalarRef', via {$$_}, inline {'$$value'};
inflate 'ScalarRef', via { \$_ }, inline {'\$value'};

deflate 'Item', via {$_}, inline {'$value'};
inflate 'Item', via {$_}, inline {'$value'};

deflate 'HashRef[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    my $value = {%$_};
    while ( my ( $k, $v ) = each %$value ) {
        $value->{$k}
            = $deflate->( $value->{$k}, $constraint->type_parameter );
    }
    return $deflate->( $value, $constraint->parent );
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parent    = $deflators->( $constraint->parent );
    my $parameter = $deflators->( $constraint->type_parameter );
    return join( "\n",
        '$value = {%$value};',
        'while ( my ( $k, $v ) = each %$value ) {',
        '$value->{$k} = do {',
        '    my $value = $value->{$k};',
        '    $value = do {',
        $parameter->( $constraint->type_parameter, @_ ),
        '    };',
        '  };',
        '}',
        $parent->( $constraint->parent, @_ ),
    );
};

inflate 'HashRef[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    my $value = $inflate->( $_, $constraint->parent );
    while ( my ( $k, $v ) = each %$value ) {
        $value->{$k}
            = $inflate->( $value->{$k}, $constraint->type_parameter );
    }
    return $value;
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parent    = $deflators->( $constraint->parent );
    my $parameter = $deflators->( $constraint->type_parameter );
    return join( "\n",
        '$value = do {',
        $parent->( $constraint->parent, @_ ),
        ' };',
        'while ( my ( $k, $v ) = each %$value ) {',
        '  $value->{$k} = do {',
        '    my $value = $value->{$k};',
        '    $value = do {',
        $parameter->( $constraint->type_parameter, @_ ),
        '    };',
        '  };',
        '}',
        '$value',
    );
};

deflate 'ArrayRef[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    my $value = [@$_];
    $_ = $deflate->( $_, $constraint->type_parameter ) for (@$value);
    return $deflate->( $value, $constraint->parent );
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parent    = $deflators->( $constraint->parent );
    my $parameter = $deflators->( $constraint->type_parameter );
    return join( "\n",
        '$value = [@$value];',
        'for( @$value ) {',
        '  $_ = do {',
        '    my $value = $_;',
        '    $value = do {',
        $parameter->( $constraint->type_parameter, @_ ),
        '    };',
        '  };',
        '}',
        $parent->( $constraint->parent, @_ ),
    );
};

inflate 'ArrayRef[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    my $value = $inflate->( $_, $constraint->parent );
    $_ = $inflate->( $_, $constraint->type_parameter ) for (@$value);
    return $value;
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parent    = $deflators->( $constraint->parent );
    my $parameter = $deflators->( $constraint->type_parameter );
    return join( "\n",
        '$value = do {',
        $parent->( $constraint->parent, @_ ),
        ' };',
        'for( @$value ) {',
        '  $_ = do {',
        '    my $value = $_;',
        '    $value = do {',
        $parameter->( $constraint->type_parameter, @_ ),
        '    };',
        '  };',
        '}',
        '$value',
    );
};

deflate 'Maybe[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    return $deflate->( $_, $constraint->type_parameter );
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    return $deflators->( $constraint->type_parameter )
        ->( $constraint->type_parameter, @_ );
};

inflate 'Maybe[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    return $inflate->( $_, $constraint->type_parameter );
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    return $deflators->( $constraint->type_parameter )
        ->( $constraint->type_parameter, @_ );
};

deflate 'ScalarRef[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    return ${ $deflate->( $_, $constraint->type_parameter ) };
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parameter = $deflators->( $constraint->type_parameter );
    return join( "\n",
        '$value = do {',
        $parameter->( $constraint->type_parameter, @_ ),
        '};', '$$value' );
};

inflate 'ScalarRef[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    return \$inflate->( $_, $constraint->type_parameter );
}, inline {
    my $constraint = shift;
    my ( $attr, $deflators ) = @_;
    my $parameter = $deflators->( $constraint->type_parameter );
    return join( "\n",
        '$value = do {',
        $parameter->( $constraint->type_parameter, @_ ),
        '};', '\$value' );
};

1;

__END__

=head1 SYNOPSIS

  use MooseX::Attribute::Deflator::Moose;
  
=head1 DESCRIPTION

Using this module registers sane type deflators and inflators for Moose's built in types.

Some notes:

=over

=item * HashRef and ArrayRef deflate/inflate using JSON

=item * ScalarRef is dereferenced on deflation and returns a reference on inflation

=back
