package Types;

use MooseX::Types -declare => ['MyHashRef'];
use MooseX::Types::Moose qw/HashRef/;
use MooseX::Attribute::Deflator;

use JSON;

subtype MyHashRef, 
	as HashRef;
	
deflate MyHashRef,
	via { encode_json($_) };


1;