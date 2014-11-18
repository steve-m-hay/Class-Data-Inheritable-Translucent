package Class::Data::Inheritable::Translucent;

use 5.008001;

use strict;
use warnings;

=head1 NAME

Class::Data::Inheritable::Translucent - Inheritable, overridable, translucent class data / object attributes

=cut

use constant _ATTR_TYPE_CLASS       => 1;
use constant _ATTR_TYPE_TRANSLUCENT => 2;

our $VERSION = '1.05';

if (eval { require Sub::Name }) {
    Sub::Name->import;
}

=head1 SYNOPSIS

  package Foo;
  use base qw(Class::Data::Inheritable::Translucent);

  Foo->mk_class_accessor("cbar");
  Foo->mk_translucent_accessor("tbar");

  Foo->cbar("baz");
  Foo->tbar("baz");
  $obj = Foo->new;
  print $obj->cbar; # prints "baz"
  print $obj->tbar; # prints "baz"
  print Foo->cbar;  # prints "baz"
  print Foo->tbar;  # prints "baz"

  $obj->cbar("whatever");
  $obj->tbar("whatever");
  print $obj->cbar; # prints "whatever"
  print $obj->tbar; # prints "whatever"
  print Foo->cbar;  # prints "whatever"
  print Foo->tbar;  # prints "baz"

  Foo->cbar("qux");
  Foo->tbar("qux");
  print $obj->cbar; # prints "qux"
  print $obj->tbar; # prints "whatever"
  print Foo->cbar;  # prints "qux"
  print Foo->tbar;  # prints "qux"

  $obj->cbar(undef);
  $obj->tbar(undef);
  print $obj->cbar; # prints nothing
  print $obj->tbar; # prints "qux"
  print Foo->cbar;  # prints nothing
  print Foo->tbar;  # prints "qux"

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

=cut

sub mk_class_accessor {
    my($class, $attribute, $value) = @_;
    return $class->_mk_accessor($attribute, $value, _ATTR_TYPE_CLASS);
}

sub mk_translucent_accessor{
    my($class, $attribute, $value) = @_;
    return $class->_mk_accessor($attribute, $value, _ATTR_TYPE_TRANSLUCENT);
}

*mk_translucent = \&mk_translucent_accessor;

sub _mk_accessor {
    my($declaredclass, $attribute, $value, $type) = @_;

    if (ref $declaredclass) {
        my $caller = (caller(1))[3];
        $caller =~ s/^.*:://o;
        require Carp;
        Carp::croak("$caller() is a class method, not an object method");
    }

    my $translucentattr = ($type == _ATTR_TYPE_TRANSLUCENT);

    my $accessor = sub {
        my $object = ref $_[0] ? $_[0] : undef;
        my $usingobject = ($translucentattr && $object);
        my $class = ref $_[0] || $_[0];

        return $class->_mk_accessor($attribute, $value, $type)->(@_)
          if @_ > 1 && !$usingobject && $class ne $declaredclass;

        if ($usingobject) {
            my $attrs = $object->attrs();
            $attrs->{$attribute} = $_[1] if @_ > 1;
            return $attrs->{$attribute} if defined $attrs->{$attribute};
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

=pod

=item B<attrs>

This method is called by the generated accessors and, by default, simply
returns the object that called it, which should be a hash reference for storing
object attributes.  If your objects are not hashrefs, or you wish to store your
object attributes in a different location, e.g. $object->{attrs}, then you
should override this method.  Class::Data::Inheritable::Translucent stores the
value of object attribute $attribute in $object->attrs()->{$attribute}.

=cut

sub attrs {
    return $_[0];
}

=pod

=back

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
support non hash-based objects, does blindly overwrite any existing methods, and
it also doesn't support the use of C<undef> to wipe out an overridden object
attribute's value and reinherit the class default.  It has also been deprecated
in favour of L<Class::Accessor::Grouped> (or L<Moose>).

=item *

L<Class::Accessor::Grouped> - The C<inherited> accessor type also does the same
thing as the mk_translucent_accessor() part of this module.

However, as of version 0.10010, whilst it does make use of L<Sub::Name>, it
still doesn't support non hash-based objects, does blindly overwrite existing
methods, and doesn't support C<undef> to reset an overridden object attribute's value

=item *

L<perltooc> - Tom's OO Tutorial for Class Data in Perl - a pretty nice Class
Data tutorial for Perl

=item *

The source.  It's quite short, and simple enough.

=back

=cut

1; # End of Class::Data::Inheritable::Translucent
