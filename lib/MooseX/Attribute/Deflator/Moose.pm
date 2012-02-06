package MooseX::Attribute::Deflator::Moose;

# ABSTRACT: Deflators for Moose type constraints

use MooseX::Attribute::Deflator;
use JSON;

deflate [qw(ArrayRef HashRef)], via { JSON::encode_json($_) },
    inline {'JSON::encode_json($value)'};
inflate [qw(ArrayRef HashRef)], via { JSON::decode_json($_) },
    inline {'JSON::decode_json($value)'};

deflate 'ScalarRef', via {$$_}, inline {'$$value'};
inflate 'ScalarRef', via { \$_ }, inline {'\$value'};

deflate 'Bool', via { $_ ? JSON::XS::true : JSON::XS::false },
    inline {'$value ? JSON::XS::true : JSON::XS::false'};
inflate 'Bool', via { $_ ? 1 : 0 }, inline {'$value ? 1 : 0'};

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
    my ( $attr, $constraint, $deflators ) = @_;
    my $parent    = $deflators->( $constraint->parent );
    my $parameter = $deflators->( $constraint->type_parameter );
    return join( "\n",
        '$value = {%$value};',
        'while ( my ( $k, $v ) = each %$value ) {',
        '$value->{$k} = do {',
        '    my $value = $value->{$k};',
        '    $value = do {',
        $parameter,
        '    };',
        '  };',
        '}',
        $parent,
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
    my ( $attr, $constraint, $deflators ) = @_;
    my $parent    = $deflators->( $constraint->parent );
    my $parameter = $deflators->( $constraint->type_parameter );
    return join( "\n",
        '$value = do {',
        $parent,
        ' };',
        'while ( my ( $k, $v ) = each %$value ) {',
        '  $value->{$k} = do {',
        '    my $value = $value->{$k};',
        '    $value = do {',
        $parameter,
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
    my ( $attr, $constraint, $deflators ) = @_;
    my $parent    = $deflators->( $constraint->parent );
    my $parameter = $deflators->( $constraint->type_parameter );
    return join( "\n",
        '$value = [@$value];',
        'for( @$value ) {',
        '  $_ = do {',
        '    my $value = $_;',
        '    $value = do {',
        $parameter,
        '    };',
        '  };',
        '}',
        $parent,
    );
};

inflate 'ArrayRef[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    my $value = $inflate->( $_, $constraint->parent );
    $_ = $inflate->( $_, $constraint->type_parameter ) for (@$value);
    return $value;
}, inline {
    my ( $attr, $constraint, $deflators ) = @_;
    my $parent    = $deflators->( $constraint->parent );
    my $parameter = $deflators->( $constraint->type_parameter );
    return join( "\n",
        '$value = do {',
        $parent,
        ' };',
        'for( @$value ) {',
        '  $_ = do {',
        '    my $value = $_;',
        '    $value = do {',
        $parameter,
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
    my ( $attr, $constraint, $deflators ) = @_;
    return $deflators->( $constraint->type_parameter );
};

inflate 'Maybe[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    return $inflate->( $_, $constraint->type_parameter );
}, inline {
    my ( $attr, $constraint, $deflators ) = @_;
    return $deflators->( $constraint->type_parameter );
};

deflate 'ScalarRef[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    return ${ $deflate->( $_, $constraint->type_parameter ) };
}, inline {
    my ( $attr, $constraint, $deflators ) = @_;
    my $parameter = $deflators->( $constraint->type_parameter );
    return join( "\n",
        '$value = do {',
        $parameter,
        '};', '$$value' );
};

inflate 'ScalarRef[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    return \$inflate->( $_, $constraint->type_parameter );
}, inline {
    my ( $attr, $constraint, $deflators ) = @_;
    my $parameter = $deflators->( $constraint->type_parameter );
    return join( "\n",
        '$value = do {',
        $parameter,
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
