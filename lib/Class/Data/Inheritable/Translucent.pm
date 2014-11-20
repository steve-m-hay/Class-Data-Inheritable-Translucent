package Class::Data::Inheritable::Translucent;

use 5.008001;

use strict;
use warnings;

use constant _ATTR_TYPE_CLASS       => 1;
use constant _ATTR_TYPE_TRANSLUCENT => 2;
use constant _ATTR_TYPE_OBJECT      => 3;

our $VERSION = '2.00';

if (eval { require Sub::Name }) {
    Sub::Name->import;
}

sub mk_class_accessor {
    my($class, $attribute, $value) = @_;
    return $class->_mk_accessor($attribute, $value, _ATTR_TYPE_CLASS);
}

sub mk_translucent_accessor{
    my($class, $attribute, $value) = @_;
    return $class->_mk_accessor($attribute, $value, _ATTR_TYPE_TRANSLUCENT);
}

*mk_translucent = \&mk_translucent_accessor;

sub mk_object_accessor {
    my($class, $attribute, $value) = @_;
    return $class->_mk_accessor($attribute, $value, _ATTR_TYPE_OBJECT);
}

sub _mk_accessor {
    my($declaredclass, $attribute, $value, $type) = @_;

    if (ref $declaredclass) {
        my $caller = (caller(1))[3];
        $caller =~ s/^.*:://o;
        require Carp;
        Carp::croak("$caller() is a class method, not an object method");
    }

    my $translucentattr = ($type == _ATTR_TYPE_TRANSLUCENT);
    my $objectattr      = ($type == _ATTR_TYPE_OBJECT);

    my $accessor = sub {
        my $object = ref $_[0] ? $_[0] : undef;

        if ($objectattr and not $object) {
            my $caller = (caller(0))[3];
            $caller =~ s/^.*:://o;
            require Carp;
            Carp::croak("$caller() is an object method, not a class method");
        }

        my $usingobject = (($translucentattr && $object) || $objectattr);
        my $class = ref $_[0] || $_[0];

        return $class->_mk_accessor($attribute, $value, $type)->(@_)
          if @_ > 1 && !$usingobject && $class ne $declaredclass;

        if ($usingobject) {
            my $attrs = $object->attrs();
            $attrs->{$attribute} = $_[1] if @_ > 1;
            return $attrs->{$attribute} if exists $attrs->{$attribute};
        }
        else {
            $value = $_[1] if @_ > 1;
        }

        return $value;
    };

    my $name = "${declaredclass}::$attribute";
    my $subnamed = 0;
    unless (defined &{$name}) {
        subname($name, $accessor) if defined &subname;
        $subnamed = 1;
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{$name}  = $accessor;
    }

    my $alias = "${declaredclass}::_${attribute}_accessor";
    unless (defined &{$alias}) {
        subname($alias, $accessor) if defined &subname and not $subnamed;
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{$alias} = $accessor;
    }

    return $accessor;
}

sub attrs {
    return $_[0];
}

1;

__END__

=head1 NAME

Class::Data::Inheritable::Translucent - Inheritable, overridable, translucent class data / object attributes

=head1 SYNOPSIS

  package Foo;
  use parent qw(Class::Data::Inheritable::Translucent);
  sub new { bless {}, shift }

  Foo->mk_class_accessor(cattr => "bar");
  Foo->mk_translucent_accessor(tattr => "bar");
  Foo->mk_object_accessor(oattr => "bar");

  my $obj = Foo->new;
  print $obj->cattr; # prints "bar"
  print $obj->tattr; # prints "bar"
  print $obj->oattr; # prints "bar"
  print Foo->cattr;  # prints "bar"
  print Foo->tattr;  # prints "bar"

  $obj->cattr("baz");
  $obj->tattr("baz");
  $obj->oattr("baz");
  print $obj->cattr; # prints "baz"
  print $obj->tattr; # prints "baz"
  print $obj->oattr; # prints "baz"
  print Foo->cattr;  # prints "baz"
  print Foo->tattr;  # prints "bar"

  Foo->cattr("qux");
  Foo->tattr("qux");
  print $obj->cattr; # prints "qux"
  print $obj->tattr; # prints "baz"
  print Foo->cattr;  # prints "qux"
  print Foo->tattr;  # prints "qux"

  delete $obj->{tattr};
  delete $obj->{oattr};
  print $obj->tattr; # prints "qux"
  print $obj->oattr; # prints "bar"
  print Foo->tattr;  # prints "qux"

=head1 DESCRIPTION

This module is based on Class::Data::Inheritable, and is largely the same
except the class data accessors optionally double as translucent object
attribute accessors.

The value of object attribute $attribute, by default, is stored in
$object->{$attribute}.  See the attrs() method, explained below, on how to
change that.

=head1 METHODS

=over

=item B<mk_class_accessor>

Creates an accessor for inheritable, overridable class data.  Does not install
the accessor method if a subroutine of the same name already exists; likewise
for the alias method (_E<lt>attributeE<gt>_accessor()).

=item B<mk_translucent_accessor>

Creates an accessor for inheritable, overridable class data which doubles as a
translucent object attribute accessor.  Does not install the accessor method if
a subroutine of the same name already exists; likewise for the alias method
(_E<lt>attributeE<gt>_accessor()).

=item B<mk_translucent>

Alias for mk_translucent_accessor(), for backwards compatibility.

=item B<mk_object_accessor>

Creates a non-translucent object attribute accessor.  Does not
install the accessor method if a subroutine of the same name already exists;
likewise for the alias method (_E<lt>attributeE<gt>_accessor()).

=item B<attrs>

This method is called by the generated accessors and, by default, simply
returns the object that called it, which should be a hash reference for storing
object attributes.  If your objects are not hashrefs, or you wish to store your
object attributes in a different location, e.g. $object->{attrs}, then you
should override this method.  Class::Data::Inheritable::Translucent stores the
value of object attribute $attribute in $object->attrs()->{$attribute}.

=back

=head1 COMPATIBILITY

Before version 2.00 of this module, an object attribute that had been set to
override translucent class data could be "reset" to reveal the inherited class
data value by setting it to the undefined value.

As of version 2.00 of this module, the attribute must now be deleted from the
object in order to have the same effect.  If your objects are hashrefs then this
is done simply with "delete $object->{$attribute}"; more generally, and in
particular if you have overridden attrs(), this is done with
"delete $object->attrs()->{$attribute}".

B<THIS IS AN INCOMPATIBLE CHANGE.  EXISTING SOFTWARE THAT USES THIS FEATURE WILL
NEED TO BE MODIFIED.>

=head1 AUTHOR

Ryan McGuigan

Based on Class::Data::Inheritable, originally by Damian Conway

Steve Hay E<lt>F<shay@cpan.org>E<gt> is now maintaining
Class::Data::Inheritable::Translucent as of version 1.00

=head1 ACKNOWLEDGEMENTS

Thanks to Damian Conway for L<Class::Data::Inheritable>

=head1 COPYRIGHT & LICENSE

Version 0.01 Copyright 2005 Ryan McGuigan, all rights reserved.
Changes in Version 1.00 onwards Copyright (C) 2009, 2011, 2014 Steve Hay.  All
rights reserved.

_mk_accessor is based on mk_classdata from Class::Data::Inheritable,
Copyright Damian Conway and Michael G Schwern, licensed under the terms of the
Perl Artistic License.

This program is free software; It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
L<http://www.perl.com/perl/misc/Artistic.html>)

=head1 BUGS

Please report any bugs or feature requests on the CPAN Request Tracker at
F<http://rt.cpan.org/Public/Bug/Report.html?Queue=Class-Data-Inheritable-Translucent>.

=head1 SEE ALSO

=over 2

=item *

L<Class::Data::Inheritable> - An almost exact duplicate of the
mk_class_accessor() part of this module, which this module was based on.

However, as of version 0.08, it doesn't make use of L<Sub::Name> (so all
accessor methods created by it will show up as C<__ANON__> in, e.g. profiling
tools), it doesn't support non hash-based objects, and it will blindly overwrite
any existing (accessor) methods.

=item *

L<Class::Data::Accessor> - An almost exact duplicate of the
mk_translucent_accessor() part of this module, created only a fortnight before
it!

However, as of version 0.04004, it also doesn't make use of L<Sub::Name> or
support non hash-based objects and does overwrite any existing methods.  It has
also been deprecated in favour of L<Class::Accessor::Grouped> (or L<Moose>).

=item *

L<Class::Accessor::Grouped> - The C<inherited> accessor type also does the same
thing as the mk_translucent_accessor() part of this module.

However, as of version 0.10012, whilst it does make use of L<Sub::Name>, it
doesn't support non hash-based objects and does overwrite any existing methods.

=item *

L<perltooc> - Tom's OO Tutorial for Class Data in Perl - a pretty nice Class
Data tutorial for Perl

=item *

The source.  It's quite short, and simple enough.

=back

=cut
