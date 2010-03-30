package MooseX::Attribute::Deflator::Moose;
# ABSTRACT: Deflators for Moose type constraints

use MooseX::Attribute::Deflator;
use JSON;


deflate 'HashRef', via { JSON::encode_json($_) };
inflate 'HashRef', via { JSON::decode_json($_) };

deflate 'ArrayRef', via { JSON::encode_json($_) };
inflate 'ArrayRef', via { JSON::decode_json($_) };

deflate 'ScalarRef', via { $$_ };
inflate 'ScalarRef', via { \$_ };

deflate 'Item', via { $_ };
inflate 'Item', via { $_ };

deflate 'HashRef[]', via {
    my ($obj, $constraint, $deflate) = @_;
    my $value = {%$_};
    while(my($k,$v) = each %$value) {
        $value->{$k} = $deflate->($value->{$k}, $constraint->type_parameter);
    }
    return $deflate->($value, $constraint->parent);
};

inflate 'HashRef[]', via {
    my ($obj, $constraint, $inflate) = @_;
    my $value = $inflate->($_, $constraint->parent);
    while(my($k,$v) = each %$value) {
        $value->{$k} = $inflate->($value->{$k}, $constraint->type_parameter);
    }
    return $value;
};

deflate 'ArrayRef[]', via {
    my ($obj, $constraint, $deflate) = @_;
    my $value = [@$_];
    $_ = $deflate->($_, $constraint->type_parameter) for(@$value);
    return $deflate->($value, $constraint->parent);
};

inflate 'ArrayRef[]', via {
    my ($obj, $constraint, $inflate) = @_;
    my $value = $inflate->($_, $constraint->parent);
    $_ = $inflate->($_, $constraint->type_parameter) for(@$value);
    return $value;
};

deflate 'Maybe[]', via {
    my ($obj, $constraint, $deflate) = @_;
    return $deflate->($_, $constraint->type_parameter);
};

inflate 'Maybe[]', via {
    my ($obj, $constraint, $inflate) = @_;
    return $inflate->($_, $constraint->type_parameter);
};

1;