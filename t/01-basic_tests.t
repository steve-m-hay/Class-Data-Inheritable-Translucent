#!perl -T

use 5.008001;

use strict;
use warnings;

use Test::More tests => 22;

package Foo;
use base 'Class::Data::Inheritable::Translucent';

__PACKAGE__->mk_translucent_accessor(foo => "base");
__PACKAGE__->mk_translucent_accessor(bar => "inherited");
__PACKAGE__->mk_translucent_accessor(baz => "object");
__PACKAGE__->mk_translucent_accessor(attr => 1);
__PACKAGE__->mk_ro_translucent_accessor(ro => "readonly");
sub attr { return 2 }
sub _attr_accessor { return 3 }

sub new {
    return bless {}, shift;
}

package Bar;
use base 'Foo';

package main;

is(Foo->foo, "base", "mk_translucent_accessor Ok");
Foo->foo("foobar");
is(Foo->foo, "foobar", "class data Ok");

is(Bar->bar, "inherited", "inheritance Ok");
Bar->bar("seedy bar");
is(Bar->bar, "seedy bar", "inheritance 2 Ok");

my $obj  = Foo->new;
is($obj->baz, "object", "see thru Ok");
$obj->baz("object a");
is($obj->baz, "object a", "translucency Ok");
is(Foo->baz, "object", "class default Ok");
delete $obj->{baz};
is($obj->baz, "object", "reset Ok");
is(Foo->baz, "object", "class default still Ok");

my $subobj = Bar->new;
is($subobj->baz, "object", "sub-class see thru Ok");
$subobj->baz("object a");
is($subobj->baz, "object a", "sub-class translucency Ok");
is(Bar->baz, "object", "sub-class default Ok");
Foo->baz("whatever");
is(Bar->baz, "whatever", "sub-class default not overridden");
delete $subobj->{baz};
is($subobj->baz, "whatever", "sub-class reset Ok");
is(Bar->baz, "whatever", "sub-class default still Ok");
Foo->baz("object");
is(Bar->baz, "object", "sub-class default still not overridden");

is(Foo->attr, "2", "Existing name is not ovewrwritten");
is(Foo->_attr_accessor, "3", "Existing alias is not ovewrwritten");

is(Foo->ro, "readonly", "readonly attribute Ok thru class");
is($obj->ro, "readonly", "readonly attribute Ok thru object");
eval { Foo->ro(2) };
ok $@ =~ /^'ro' is a read-only attribute/,
   "readonly attribute can't be written thru class";
eval { $obj->ro(2) };
ok $@ =~ /^'ro' is a read-only attribute/,
   "readonly attribute can't be written thru object";
