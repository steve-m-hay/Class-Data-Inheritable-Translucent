#===============================================================================
#
# lib/Class/Data/Inheritable/Translucent.pm
#
# DESCRIPTION
#   Abstract base class providing class methods for creating accessors for
#   inheritable, overridable and optionally translucent class data and for
#   object attributes with default values.
#
# COPYRIGHT
#   Version 0.01 Copyright (C) 2005 Ryan McGuigan.  All rights reserved.
#   Changes in Version 1.00 onwards Copyright (C) 2009, 2011, 2014-2015 Steve
#   Hay.  All rights reserved.
#
# LICENCE
#   This module is free software; you can redistribute it and/or modify it under
#   the same terms as Perl itself, i.e. under the terms of either the GNU
#   General Public License or the Artistic License, as specified in the LICENCE
#   file.
#
#===============================================================================

package Class::Data::Inheritable::Translucent;

use 5.008001;

use strict;
use warnings;

# See CPAN RT#82921 / Perl-Critic Issue 499.
## no critic (Modules::ProhibitEvilModules)

use Carp qw(carp croak);
use Class::ISA qw();
BEGIN { eval { require Sub::Name } and Sub::Name->import(qw(subname)) }

use constant _ATTR_TYPE_CLASS       => 1;
use constant _ATTR_TYPE_TRANSLUCENT => 2;
use constant _ATTR_TYPE_OBJECT      => 3;

use constant _ACCESS_TYPE_READONLY  => 1;
use constant _ACCESS_TYPE_READWRITE => 2;

#===============================================================================
# CLASS INITIALIZATION
#===============================================================================

our($VERSION);

BEGIN {
    $VERSION = '2.00';
}

#===============================================================================
# PROTECTED METHODS
#===============================================================================

#-------------------------------------------------------------------------------
# Class methods
#-------------------------------------------------------------------------------

sub mk_class_accessor {
    my($class, $attr, $value) = @_;
    return $class->_mk_accessor($attr, $value,
                                _ATTR_TYPE_CLASS, _ACCESS_TYPE_READWRITE);
}

sub mk_translucent_accessor {
    my($class, $attr, $value) = @_;
    return $class->_mk_accessor($attr, $value,
                                _ATTR_TYPE_TRANSLUCENT, _ACCESS_TYPE_READWRITE);
}

sub mk_object_accessor {
    my($class, $attr, $value) = @_;
    return $class->_mk_accessor($attr, $value,
                                _ATTR_TYPE_OBJECT, _ACCESS_TYPE_READWRITE);
}

sub mk_ro_class_accessor {
    my($class, $attr, $value) = @_;
    return $class->_mk_accessor($attr, $value,
                                _ATTR_TYPE_CLASS, _ACCESS_TYPE_READONLY);
}

sub mk_ro_translucent_accessor {
    my($class, $attr, $value) = @_;
    return $class->_mk_accessor($attr, $value,
                                _ATTR_TYPE_TRANSLUCENT, _ACCESS_TYPE_READONLY);
}

sub mk_ro_object_accessor {
    my($class, $attr, $value) = @_;
    return $class->_mk_accessor($attr, $value,
                                _ATTR_TYPE_OBJECT, _ACCESS_TYPE_READONLY);
}

*mk_translucent = \&mk_translucent_accessor;

sub _mk_accessor {
    my($declaredclass, $attr, $value, $type, $access) = @_;

    if (ref $declaredclass) {
        my $caller = (caller(1))[3];
        $caller =~ s/^.*:://o;
        croak("$caller() is a class method, not an object method");
    }

    if ($attr eq 'DESTROY') {
        carp("Having an accessor named 'DESTROY' in '$declaredclass' is " .
             "unwise.");
    }

    $declaredclass->_add_attr($attr, $type, $access);

    my $translucentattr = ($type == _ATTR_TYPE_TRANSLUCENT);
    my $objectattr      = ($type == _ATTR_TYPE_OBJECT);
    my $readonlyattr    = ($access == _ACCESS_TYPE_READONLY);

    my $accessor = sub {
        my $object = ref $_[0] ? $_[0] : undef;

        if ($objectattr and not $object) {
            croak("$attr() is an object method, not a class method");
        }

        # Disallow setting a read-only attribute except when working on an
        # object that is not yet initialized.
        if ($readonlyattr and @_ > 1) {
            if (not $object or $object->_initialized()) {
                croak("'$attr' is a read-only attribute");
            }
        }

        if (($translucentattr && $object) || $objectattr) {
            my $attrs = $object->attrs();
            return $attrs->{$attr} = $_[1] if @_ > 1;
            return $attrs->{$attr} if exists $attrs->{$attr};
        }
        elsif (@_ > 1) {
            my $class = ref $_[0] || $_[0];
            return $class->_mk_accessor($attr, $value, $type, $access)->(@_)
                if $class ne $declaredclass;
            return $value = $_[1];
        }

        return $value;
    };

    my $name = "${declaredclass}::$attr";
    my $subnamed = 0;
    unless (defined &{$name}) {
        subname($name, $accessor) if defined &subname;
        $subnamed = 1;
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{$name}  = $accessor;
    }

    my $alias = "${declaredclass}::_${attr}_accessor";
    unless (defined &{$alias}) {
        subname($alias, $accessor) if defined &subname and not $subnamed;
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{$alias} = $accessor;
    }

    return $accessor;
}

#-------------------------------------------------------------------------------
# Object methods
#-------------------------------------------------------------------------------

#
# Overridable.
#
sub attrs {
    return $_[0];
}

#
# Overridable.
#
sub _initialized {
    return 1;
}

{

my %_Attrs = ();

#-------------------------------------------------------------------------------
# Class methods
#-------------------------------------------------------------------------------

#
# Adds an attribute of the given type and access type to the invocent class,
# checking that there is no conflicting attribute first.
# Returns true or else throws an exception.
#
sub _add_attr {
    my($class, $attr, $type, $access) = @_;

    if (exists $_Attrs{$class} and exists $_Attrs{$class}{$attr}) {
        croak("Duplicate attribute '$attr' in class '$class'");
    }

    foreach my $super_class (Class::ISA::super_path($class)) {
        next unless (exists $_Attrs{$super_class} and
                     exists $_Attrs{$super_class}{$attr});

        my $data = $_Attrs{$super_class}{$attr};
        if ($data->{type} != $type or $data->{access} != $access) {
            croak("Conflicting attribute '$attr' in superclass '$super_class'");
        }
    }

    $_Attrs{$class}{$attr} = {
        type   => $type,
        access => $access
    };

    return 1;
}

#-------------------------------------------------------------------------------
# Object methods
#-------------------------------------------------------------------------------

#
# Returns a list of the object attributes and translucent attributes (since they
# double as object attributes) of the invocant object. Includes any attributes
# inherited from superclasses. If the object is in an initialized state then
# read-only attributes are not included.
#
sub _get_editable_attrs {
    my($self, $all) = @_;
    my $class = ref $self;

    my $initialized = $self->_initialized();

    my %attrs = ();
    foreach my $super_class (Class::ISA::self_and_super_path($class)) {
        next unless exists $_Attrs{$super_class};

        foreach my $attr (keys %{$_Attrs{$super_class}}) {
            my $data = $_Attrs{$super_class}{$attr};
            next if $data->{type} == _ATTR_TYPE_CLASS;

            if (!$initialized or $data->{access} != _ACCESS_TYPE_READONLY) {
                $attrs{$attr} = 1;
            }
        }
    }

    return keys %attrs;
}

}

1;

__END__

#===============================================================================
# DOCUMENTATION
#===============================================================================

=head1 NAME

Class::Data::Inheritable::Translucent - Inheritable, overridable, translucent class data / object attributes

=head1 SYNOPSIS

  package Foo;
  use parent qw(Class::Data::Inheritable::Translucent);
  sub new { bless {}, shift }

  # Read/write attributes
  Foo->mk_class_accessor(cattr => "bar");
  Foo->mk_translucent_accessor(tattr => "bar");
  Foo->mk_object_accessor(oattr => "bar");

  # Read-only attributes
  Foo->mk_ro_class_accessor(foo => 1);
  Foo->mk_ro_translucent_accessor(bar => 1);
  Foo->mk_ro_object_accessor(baz => 1);

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

This module is based on Class::Data::Inheritable; the mk_class_accessor()
method is largely the same as Class::Data::Inheritable's mk_classdata() method,
but mk_translucent_accessor() creates class data accessors that double as
translucent object attribute accessors.  Accessors for plain object attributes
can also be created with mk_object_accessor().  Read-only accessors for all
three types of data/attributes can also be created with mk_ro_class_accessor(),
mk_ro_translucent_accessor() and mk_ro_object_accessor().

Your class should inherit from Class::Data::Inheritable::Translucent and call
the relevant mk_*_accessor() methods during its initialization.  If you are
making use of object accessor methods (translucent or otherwise) then your class
will also need to have a constructor method to create objects.  By default, the
objects are assumed to be hash references with their attributes stored directly
inside them, i.e. the value of object $obj's attribute $attr is assumed to be
stored in $obj->{$attr}.  See the attrs() method on how to change that.  If a
simple hash-based object is all you need then you can have a constructor method
provided for you by inheriting from
L<Class::Data::Inheritable::Translucent::Object> or
L<Class::Data::Inheritable::Translucent::Singleton> instead.

Note that the accessor methods created by this module only perform shallow
copies of attribute values.  Therefore, different classes and/or objects will
end up sharing some data if any attribute values are set to references.

=head2 Class Methods

=over 4

=item C<mk_class_accessor($attribute [, $default ])>

Static method to create an accessor for an inheritable, overridable class
attribute called $attribute with default value $default in the invocant class.
Does not install the accessor method if a subroutine of the same name already
exists; likewise for the alias method (_E<lt>attributeE<gt>_accessor()).

=item C<mk_translucent_accessor($attribute [, $default ])>

Static method to create an accessor for an inheritable, overridable class
attribute called $attribute with default value $default which doubles as a
translucent object attribute accessor.  Does not install the accessor method if
a subroutine of the same name already exists; likewise for the alias method
(_E<lt>attributeE<gt>_accessor()).

=item C<mk_translucent($attribute [, $default ])>

Alias for mk_translucent_accessor(), for backwards compatibility.

=item C<mk_object_accessor($attribute [, $default ])>

Static method to create an accessor for a non-translucent object attribute
called $attribute with default value $default.  Does not install the accessor
method if a subroutine of the same name already exists; likewise for the alias
method (_E<lt>attributeE<gt>_accessor()).

=item C<mk_ro_class_accessor($attribute [, $default ])>

Same as C<mk_class_accessor> except that the attribute is read-only.  As with
read-only static fields in C#, the value can only be set during class
initialization, i.e. in the mk_ro_class_accessor() call itself.

=item C<mk_ro_translucent_accessor($attribute [, $default ])>

Same as C<mk_translucent_accessor> except that the attribute is read-only.  As
with read-only static fields in C#, the class attribute value, which here
doubles as the translucent object attribute default value, can only be set
during class initialization, i.e. in the mk_ro_class_accessor() call itself, and
as with other read-only fields in C#, the object attribute value can only be set
when constructing/cloning the object.

=item C<mk_ro_object_accessor($attribute [, $default ])>

Same as C<mk_object_accessor> except that the attribute is read-only.  As with
read-only fields in C#, the value can only be set when constructing/cloning the
object.

=back

=head2 Object Methods

=over 4

=item C<attrs()>

This method is called by the generated accessors and, by default, simply
returns the object that called it, which should be a hash reference for storing
object attributes.  If your objects are not hashrefs, or you wish to store your
object attributes in a different location, e.g. $object->{attrs}, then you
should override this method.  Class::Data::Inheritable::Translucent stores the
value of object attribute $attribute in $object->attrs()->{$attribute}.

=back

=head1 DIAGNOSTICS

=head2 Warnings and Error Messages

This module may produce the following diagnostic messages.  They are classified
as follows (a la L<perldiag>):

    (W) A warning (optional).
    (F) A fatal error (trappable).
    (I) An internal error that you should never see (trappable).

=over 4

=item Conflicting attribute '%s' in superclass '%s'

(F) You tried to install the specified attribute into a class that already
inherits an attribute of the same name but of a conflicting attribute type
(class, translucent or object) or access type (read/write or read-only) from the
specified superclass.  You cannot override an attribute unless it is of the same
type.

=item Duplicate attribute '%s' in class '%s'

(F) You tried to install the specified attribute into the specified class, but
that class that already has an attribute of the same name.

=item Having an accessor named 'DESTROY' in '%s' is unwise.

(W) You tried to install an attribute named 'DESTROY' into the specified class.
This is not a wise thing to do.

=item %s() is a class method, not an object method

(F) You tried to invoke the specified method on an object, but it can only be
invoked on a class name.

=item '%s' is a read-only attribute

(F) You tried to set the value of the specified attribute, but it is a read-only
attribute.

=item %s() is an object method, not a class method

(F) You tried to invoke the specified method on a class name, but it can only be
invoked on an object.

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

=head1 FEEDBACK

Patches, bug reports, suggestions or any other feedback is welcome.

Patches can be sent as GitHub pull requests at
F<https://github.com/steve-m-hay/Class-Data-Inheritable-Translucent/pulls>.

Bug reports and suggestions can be made on the CPAN Request Tracker at
F<https://rt.cpan.org/Public/Bug/Report.html?Queue=Class-Data-Inheritable-Translucent>.

Currently active requests on the CPAN Request Tracker can be viewed at
F<https://rt.cpan.org/Public/Dist/Display.html?Status=Active;Queue=Class-Data-Inheritable-Translucent>.

Please test this distribution.  See CPAN Testers Reports at
F<http://www.cpantesters.org/> for details of how to get involved.

Previous test results on CPAN Testers Reports can be viewed at
F<http://www.cpantesters.org/distro/C/Class-Data-Inheritable-Translucent.html>.

Please rate this distribution on CPAN Ratings at
F<http://cpanratings.perl.org/rate/?distribution=Class-Data-Inheritable-Translucent>.

=head1 SEE ALSO

=over 4

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

=head1 ACKNOWLEDGEMENTS

The C<_mk_accessor()> method is based on the C<mk_classdata()> method in the
Class::Data::Inheritable module, written by Damian Conway.

=head1 AVAILABILITY

The latest version of this module is available from CPAN (see
L<perlmodlib/"CPAN"> for details) at

F<https://metacpan.org/release/Class-Data-Inheritable-Translucent> or

F<http://search.cpan.org/dist/Class-Data-Inheritable-Translucent/> or

F<http://www.cpan.org/authors/id/S/SH/SHAY/> or

F<http://www.cpan.org/modules/by-module/Class/>.

The latest source code is available from GitHub at
F<https://github.com/steve-m-hay/Class-Data-Inheritable-Translucent>.

=head1 INSTALLATION

See the F<INSTALL> file.

=head1 AUTHOR

Ryan McGuigan

Steve Hay E<lt>F<shay@cpan.org>E<gt> is now maintaining
Class::Data::Inheritable::Translucent as of version 1.00

=head1 COPYRIGHT

Version 0.01 Copyright (C) 2005 Ryan McGuigan.  All rights reserved.

Changes in Version 1.00 onwards Copyright (C) 2009, 2011, 2014-2015 Steve Hay.
All rights reserved.

=head1 LICENCE

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself, i.e. under the terms of either the GNU General Public
License or the Artistic License, as specified in the F<LICENCE> file.

=head1 VERSION

Version 2.00

=head1 DATE

TODO

=head1 HISTORY

See the F<Changes> file.

=cut

#===============================================================================
