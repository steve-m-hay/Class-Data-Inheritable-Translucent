#!perl

use 5.008001;

use strict;
use warnings;

package Foo;

use Test::More tests => 1;

use base 'Class::Data::Inheritable::Translucent';

__PACKAGE__->mk_translucent_accessor(foo => "bar");

use constant FOO   => 0;
use constant ATTRS => 1;

sub attrs {
    my $self = shift;
    $self->[ATTRS] ||= {};
    $self->[ATTRS];
}

sub new {
    my $class = shift;
    my $self = bless [qw/bar/], $class;

    return $self;
}

my $obj  = Foo->new;
$obj->foo("foo");
ok((Foo->foo eq "bar" and $obj->foo eq "foo" and $obj->[FOO] eq "bar"),
  "overriding ->attrs Ok");
