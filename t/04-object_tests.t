#!perl -T

use 5.008001;

use strict;
use warnings;

use Test::More tests => 3;

package Foo;
use base 'Class::Data::Inheritable::Translucent';

__PACKAGE__->mk_object_accessor(baz => "object");

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
