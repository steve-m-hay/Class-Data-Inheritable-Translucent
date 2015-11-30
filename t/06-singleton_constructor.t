#!perl

use 5.008001;

use strict;
use warnings;

use Test::More;

## no critic (Subroutines::ProhibitSubroutinePrototypes)

BEGIN {
    my $stderr;
    sub stderr(;$) {
        if (@_) {
            my $msg = shift;
            if (defined $msg and defined $stderr) {
                $stderr .= $msg;
            }
            else {
                $stderr  = $msg;
            }
        }

        return $stderr;
    }

    if (eval { require Apache::Singleton } or eval { require Class::Singleton })
    {
        plan tests => 31;
    }
    else {
        plan skip_all => 'Apache::Singleton and Class::Singleton not available';
    }
}

package Foo;
use base 'Class::Data::Inheritable::Translucent::Singleton';

__PACKAGE__->mk_object_accessor(bar => 1);
__PACKAGE__->mk_object_accessor(baz => 1);
__PACKAGE__->mk_ro_object_accessor(qux => 1);

package FooInitSoft;
use base 'Foo';

__PACKAGE__->mk_class_accessor(count => 0);

sub initialize {
    my($self, %args) = @_;
    my %defs = (bar => 2, qux => 2);
    %args = (%defs, %args);
    $self->count($self->count() + 1);
    $self->SUPER::initialize(%args);
}

package FooInitHard;
use base 'Foo';

__PACKAGE__->mk_class_accessor(count => 0);

sub initialize {
    my($self, %args) = @_;
    my %defs = (bar => 2, qux => 2);
    %args = (%args, %defs);
    $self->count($self->count() + 1);
    $self->SUPER::initialize(%args);
}

package main;

my $obj1 = Foo->instance;
is($obj1->bar, 1, "default constructor Ok");
is($obj1->baz, 1, "default constructor Ok");
is($obj1->qux, 1, "default constructor (read-only attribute) Ok");

my $obj2 = Foo->instance(bar => 2, qux => 2);
is($obj2->bar, 1, "override in constructor ignored");
is($obj2->qux, 1, "override in constructor (read-only attribute) ignored");

is(FooInitSoft->count, 0, "default count Ok");
my $obj3 = FooInitSoft->instance(bar => 3, baz => 3);
is($obj3->bar, 3, "override in constructor wins Ok");
is($obj3->baz, 3, "override in constructor Ok");
is($obj3->qux, 2, "override in initialize (read-only attribute) Ok");
is(FooInitSoft->count, 1, "count 1 Ok");

my $obj4 = FooInitSoft->instance();
is($obj4->bar, 3, "default constructor ignored");
is($obj4->baz, 3, "default constructor ignored");
is($obj4->qux, 2, "default constructor (read-only attribute) ignored");
is(FooInitSoft->count, 1, "count 2 Ok");

is(FooInitHard->count, 0, "default count Ok");
my $obj5 = FooInitHard->instance(bar => 3, baz => 3);
is($obj5->bar, 2, "override in initialize wins Ok");
is($obj5->baz, 3, "override in constructor Ok");
is($obj5->qux, 2, "override in initialize (read-only attribute) Ok");
is(FooInitHard->count, 1, "count 1 Ok");

my $obj6 = FooInitHard->instance();
is($obj6->bar, 2, "default constructor ignored");
is($obj6->baz, 3, "default constructor ignored");
is($obj6->qux, 2, "default constructor (read-only attribute) ignored");
is(FooInitHard->count, 1, "count 2 Ok");

{
local $SIG{__WARN__} = \&stderr;
$obj4->bar(4);
$obj4->baz(4);
stderr(undef);
$obj4->reset();
my $output = stderr();
like($output, qr/^initialize\(\) ignored the following read-only attributes: 'qux'/, "reset of read-only attribute ignored Ok");
is($obj4->bar, 2, "reset to override in initialize Ok");
is($obj4->baz, 1, "reset to default Ok");
is($obj4->qux, 2, "no reset (read-only attribute) Ok");
}

{
local $SIG{__WARN__} = \&stderr;
$obj6->bar(4);
$obj6->baz(4);
stderr(undef);
$obj6->reset();
my $output = stderr();
like($output, qr/^initialize\(\) ignored the following read-only attributes: 'qux'/, "reset of read-only attribute ignored Ok");
is($obj6->bar, 2, "reset to override in initialize Ok");
is($obj6->baz, 1, "reset to default Ok");
is($obj6->qux, 2, "no reset (read-only attribute) Ok");
}
