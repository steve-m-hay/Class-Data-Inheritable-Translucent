#!perl -T

use 5.008001;

use strict;
use warnings;

use Test::More tests => 33;

package Foo;
use base 'Class::Data::Inheritable::Translucent::Object';

__PACKAGE__->mk_object_accessor(bar => 1);
__PACKAGE__->mk_object_accessor(baz => 1);
__PACKAGE__->mk_ro_object_accessor(qux => 1);

package FooInit;
use base 'Foo';

__PACKAGE__->mk_class_accessor(count => 0);

sub initialize {
    my($self, %args) = @_;
    @args{qw(bar qux)} = (2) x 2;
    $self->count($self->count() + 1);
    $self->SUPER::initialize(%args);
}

package main;

my $obj1 = Foo->new;
is($obj1->bar, 1, "default constructor Ok");
is($obj1->baz, 1, "default constructor Ok");
is($obj1->qux, 1, "default constructor (read-only attribute) Ok");

my $obj2 = Foo->new(bar => 2, qux => 2);
is($obj2->bar, 2, "override in constructor Ok");
is($obj2->baz, 1, "no override in constructor Ok");
is($obj2->qux, 2, "override in constructor (read-only attribute) Ok");

my $obj3 = Foo->new($obj2);
is($obj3->bar, 2, "clone in constructor Ok");
is($obj3->baz, 1, "no clone in constructor Ok");
is($obj3->qux, 2, "clone in constructor (read-only attribute) Ok");

my $obj4 = Foo->new($obj2, bar => 3, qux => 3);
is($obj4->bar, 3, "override and clone in constructor Ok");
is($obj4->baz, 1, "no override or clone in constructor Ok");
is($obj4->qux, 3, "override and clone in constructor (read-only attribute) Ok");

my $obj5 = $obj2->clone();
is($obj5->bar, 2, "clone Ok");
is($obj5->baz, 1, "clone Ok");
is($obj5->qux, 2, "clone (read-only attribute) Ok");

my $obj6 = $obj2->clone(bar => 3, qux => 3);
is($obj6->bar, 3, "override in clone Ok");
is($obj6->baz, 1, "no override in clone Ok");
is($obj6->qux, 3, "override in clone (read-only attribute) Ok");

is(FooInit->count, 0, "default count Ok");
my $obj7 = FooInit->new();
is($obj7->bar, 2, "override in initialize Ok");
is($obj7->baz, 1, "no override in initialize Ok");
is($obj7->qux, 2, "override in initialize (read-only attribute) Ok");
is(FooInit->count, 1, "count 1 Ok");

my $obj8 = FooInit->new(bar => 3, baz => 3);
is($obj8->bar, 2, "override in initialize Ok");
is($obj8->baz, 3, "override in constructor Ok");
is($obj8->qux, 2, "override in initialize (read-only attribute) Ok");
is(FooInit->count, 2, "count 2 Ok");

my $obj9 = FooInit->new();

$obj9->copy($obj8);
is($obj9->bar, 2, "copy Ok");
is($obj9->baz, 3, "copy Ok");
is($obj9->qux, 2, "copy (read-only attribute) Ok");

$obj9->reset();
is($obj9->bar, 2, "reset Ok");
is($obj9->baz, 1, "reset Ok");
is($obj9->qux, 2, "reset (read-only attribute) Ok");
