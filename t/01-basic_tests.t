#!perl -T

package Foo;

use Test::More tests => 7;

use base 'Class::Data::Inheritable::Translucent';

__PACKAGE__->mk_translucent(foo => "base");
__PACKAGE__->mk_translucent(bar => "inherited");
__PACKAGE__->mk_translucent(baz => "object");

sub new {
    my $proto = shift;
    my $self = bless {};

    return $self;
}


package Bar;
use base 'Foo';


package Foo;

is(Foo->foo, "base", "mk_translucent Ok");
Foo->foo("foobar");
is(Foo->foo, "foobar", "class data Ok");

is(Bar->bar, "inherited", "inheritence Ok");
Bar->bar("seedy bar");
is(Bar->bar, "seedy bar", "inheritence 2 Ok");

my $obj  = __PACKAGE__->new;
is($obj->baz, "object", "see thru Ok");
$obj->baz("object a");
is($obj->baz, "object a", "translucency Ok");
$obj->baz(undef);
is($obj->baz, "object", "undef Ok");
