#!perl

use 5.008001;

use strict;
use warnings;

use Test::More tests => 5;

package Foo;
use base 'Class::Data::Inheritable::Translucent';

__PACKAGE__->mk_object_accessor(baz => "object");
__PACKAGE__->mk_ro_object_accessor(ro => "read-only");

sub new {
    return bless {}, shift;
}

package main;

my $obj  = Foo->new;
is($obj->baz, "object", "default Ok");
$obj->baz("object a");
is($obj->baz, "object a", "new value Ok");
delete $obj->{baz};
is($obj->baz, "object", "reset Ok");

is($obj->ro, "read-only", "read-only attribute Ok");
eval { $obj->ro(2) };
ok $@ =~ /^'ro' is a read-only attribute/,
   "read-only attribute can't be written";
