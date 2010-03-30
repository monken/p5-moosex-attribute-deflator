package MooseX::Attribute::Deflator;

use strict;
use warnings;
use Moose::Exporter;
use MooseX::Attribute::Deflator::Registry;
use JSON ();

sub via (&) { $_[0] }


Moose::Exporter->setup_import_methods(
    as_is => [
        qw( deflate inflate )
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

deflate 'MooseX::Types::Structured::Optional[]', via {
    my ($obj, $constraint, $deflate) = @_;
    return $deflate->($_, $constraint->type_parameter);
};

inflate 'MooseX::Types::Structured::Optional[]', via {
    my ($obj, $constraint, $inflate) = @_;
    return $inflate->($_, $constraint->type_parameter);
};

deflate 'MooseX::Types::Structured::Map[]', via {
    my ($obj, $constraint, $deflate) = @_;
    my $value = {%$_};
    my $constraints = $constraint->type_constraints;
    while(my($k,$v) = each %$value) {
        $value->{$k} = $deflate->($value->{$k}, $constraints->[1]);
    }
    return $deflate->($value, $constraint->parent);
};

inflate 'MooseX::Types::Structured::Map[]', via {
    my ($obj, $constraint, $inflate) = @_;
    my $value = $inflate->($_, $constraint->parent);
    my $constraints = $constraint->type_constraints;
    while(my($k,$v) = each %$value) {
        $value->{$k} = $inflate->($value->{$k}, $constraints->[1]);
    }
    return $value;
};

deflate 'MooseX::Types::Structured::Dict[]', via {
    my ($obj, $constraint, $deflate) = @_;
    my %constraints = @{$constraint->type_constraints};
    my $value = {%$_};
    while(my($k,$v) = each %$value) {
        $value->{$k} = $deflate->($value->{$k}, $constraints{$k});
    }
    return $deflate->($value, $constraint->parent);
};

inflate 'MooseX::Types::Structured::Dict[]', via {
    my ($obj, $constraint, $inflate) = @_;
    my %constraints = @{$constraint->type_constraints};
    my $value = $inflate->($_, $constraint->parent);
    while(my($k,$v) = each %$value) {
        $value->{$k} = $inflate->($value->{$k}, $constraints{$k});
    }
    return $value;
};

deflate 'MooseX::Types::Structured::Tuple[]', via {
    my ($obj, $constraint, $deflate) = @_;
    my @constraints = @{$constraint->type_constraints};
    my $value = [@$_];
    for(my $i = 0; $i < @$value; $i++) {
        $value->[$i] = $deflate->($value->[$i], $constraints[$i] || $constraints[-1]);
    }
    return $deflate->($value, $constraint->parent);
};

inflate 'MooseX::Types::Structured::Tuple[]', via {
    my ($obj, $constraint, $inflate) = @_;
    my @constraints = @{$constraint->type_constraints};
    my $value = $inflate->($_, $constraint->parent);
    for(my $i = 0; $i < @$value; $i++) {
        $value->[$i] = $inflate->($value->[$i], $constraints[$i] || $constraints[-1]);
    }
    return $value;
};



1;