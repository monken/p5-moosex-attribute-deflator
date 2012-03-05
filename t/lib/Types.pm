package Types;

use MooseX::Types -declare => ['MyHashRef', 'Die'];
use MooseX::Types::Moose qw/HashRef/;
use MooseX::Attribute::Deflator;

use JSON;

subtype MyHashRef, 
	as HashRef;
	
deflate MyHashRef,
	via { encode_json($_) };

subtype Die, as HashRef;
deflate Die, via { die "foo" }, inline_as { "die 'foo' "};

1;