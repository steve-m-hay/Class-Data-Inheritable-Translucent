#===============================================================================
#
# lib/Class/Data/Inheritable/Translucent/Object.pm
#
# DESCRIPTION
#   Abstract base class extending Class::Data::Inheritable::Translucent with
#   constructor/clone methods with separated initialization.
#
# COPYRIGHT
#   Copyright (C) 2014-2015 Steve Hay.  All rights reserved.
#
# LICENCE
#   This module is free software; you can redistribute it and/or modify it under
#   the same terms as Perl itself, i.e. under the terms of either the GNU
#   General Public License or the Artistic License, as specified in the LICENCE
#   file.
#
#===============================================================================

package Class::Data::Inheritable::Translucent::Object;

use 5.008001;

use strict;
use warnings;

use parent qw(Class::Data::Inheritable::Translucent::Base);

use Carp qw(croak);

#===============================================================================
# CLASS INITIALIZATION
#===============================================================================

our($VERSION);

BEGIN {
    $VERSION = '2.00';
}

#===============================================================================
# PUBLIC METHODS
#===============================================================================

#-------------------------------------------------------------------------------
# Class methods
#-------------------------------------------------------------------------------

sub new {
    my($class, @args) = @_;
    croak("new() is a class method, not an object method") if ref $class;
    croak("'$class' is an abstract base class") if $class eq __PACKAGE__;

    my $self = bless {}, $class;

    $self->_initializing(1);

    # If there is an odd number of @args then the first should be an object to
    # copy into our new object. Otherwise leave the new object's attributes
    # uninitialized to provide translucency where appropriate.
    if (@args % 2) {
        my $source = shift @args;
        $self->copy($source);
    }

    # Initialize attributes with any (remaining) given arguments, overriding any
    # copied or translucent attributes in the process.
    $self->initialize(@args);

    $self->_initializing(0);

    return $self;
}

#-------------------------------------------------------------------------------
# Object methods
#-------------------------------------------------------------------------------

sub clone {
    my($self, %args) = @_;
    croak("clone() is an object method, not a class method") unless ref $self;

    my $class = ref $self;
    return $class->new($self, %args);
}

sub copy {
    my($self, $source) = @_;
    croak("copy() is an object method, not a class method") unless ref $self;

    if (not $source->isa(ref $self)) {
        my $class = ref $source;
        croak("Cannot copy attributes from instance of alien class '$class'");
    }

    # If the object has already been initialized then we must only copy
    # non-read-only attributes.
    my @attrs = $self->_get_editable_attrs();
    foreach my $attr (@attrs) {
        $self->$attr($source->$attr());
    }

    return 1;
}

1;

__END__

#===============================================================================
# DOCUMENTATION
#===============================================================================

=head1 NAME

Class::Data::Inheritable::Translucent::Object - Add constructor/clone methods to Class::Data::Inheritable::Translucent

=head1 SYNOPSIS

    package Bar;
    use parent qw(Class::Data::Inheritable::Translucent::Object);

    Bar->mk_object_accessor(attr => 0);

    # Class constructor
    my $obj1 = Bar->new();
    my $obj2 = Bar->new(attr => 1);
    my $obj3 = Bar->new($obj2);
    my $obj4 = Bar->new($obj2, attr => 2);

    # Object clone
    my $obj5 = $obj2->clone();
    my $obj6 = $obj2->clone(attr => 3);

    # Object copy
    my $obj7 = $obj2->copy();

    # Object reset
    $obj7->reset();

    package Bar2;
    use parent qw(Bar);

    my $_Count = 0;

    # Separated, overridable, object initialization
    sub initialize {
        my($self, %args) = @_;
        $_Count++;
        return $self->SUPER::initialize(%args);
    }

    sub DESTROY {
        $_Count--;
    }

=head1 DESCRIPTION

This module is an abstract base class extending
L<Class::Data::Inheritable::Translucent> with constructor/clone methods with
separated initialization.  The objects constructed are simple hash-based objects
compatible with the accessor methods installed by
Class::Data::Inheritable::Translucent.

Attributes may be initialized by the constructor, either explicitly, or by
copying another object, or via a separated initialize() method which can be
overridden in subclasses.  A copy() method is also provided to copy the
attributes of one object to another, and a reset() method can be used to restore
an object's non-read-only attributes to their default values (translucent or
otherwise).

Note that all of these methods, just like the accessor methods created by
L<Class::Data::Inheritable::Translucent>, only perform shallow copies of
attribute values.

=head2 Class Methods

=over 4

=item C<new([ $obj ] [, %args ])>

Constructs an instance of the invocant class and returns it.  The object will be
a simple hash-based object compatible with the accessor methods installed by
Class::Data::Inheritable::Translucent.

The new object can optionally be initialized either by copying the attributes of
a given object, or from a named parameter list (hash) of attributes, or both--in
which case the given object is cloned first and then any supplied attributes are
used to override the defaults and copied values.

=back

=head2 Object Methods

=over 4

=item C<clone($obj [, %args ])>

Clones the given object, constructing a new instance of the same class with the
same attribute values and returns it.

The new object can optionally have its default and copied attribute values
overridden by those in a named parameter list (hash) of attributes.

This has the same effect as $class->new($obj, %args), where $class is the class
to which $obj belongs.  In other words, this behaves like a copy constructor in
C++.

=item C<copy($obj)>

Sets the non-read-only attributes of the invocant object to the same values as
those of the given object, assuming that the given object is an instance of the
same class (or a subclass) as the invocant object (otherwise it throws an
exception), and returns 1.

Read-only attributes, of course, cannot be copied so will be left unchanged.

As noted earlier, but of particular relevance here, this only performs a shallow
copy of the attributes.  Therefore, the two objects will end up sharing some
data if any attribute values are references.

=item C<initialize([ %args ])>

Inherited from L<Class::Data::Inheritable::Translucent::Base>.

=item C<reset()>

Inherited from L<Class::Data::Inheritable::Translucent::Base>.

=back

=head1 DIAGNOSTICS

=head2 Warnings and Error Messages

This module may produce the following diagnostic messages.  They are classified
as follows (a la L<perldiag>):

    (W) A warning (optional).
    (F) A fatal error (trappable).
    (I) An internal error that you should never see (trappable).

=over 4

=item Cannot copy attributes from instance of alien class '%s'

(F) You tried to copy the attributes of an object belonging to the specified
class, which is not an instance of the same class (or of a superclass) as the
object you are trying to copy values to.

=item %s() is a class method, not an object method

(F) You tried to invoke the specified method on an object, but it can only be
invoked on a class name.

=item '%s' is an abstract base class

(F) You tried to construct an instance of the specified class, but it is an
abstract base class, i.e. it cannot be instantiated.

=item %s() is an object method, not a class method

(F) You tried to invoke the specified method on a class name, but it can only be
invoked on an object.

=back

=head1 EXPORTS

I<None>.

=head1 KNOWN BUGS

I<None>.

=head1 SEE ALSO

L<Class::Data::Inheritable::Translucent::Singleton>,
L<Class::Data::Inheritable::Translucent>.

=head1 AUTHOR

Steve Hay E<lt>L<shay@cpan.org|mailto:shay@cpan.org>E<gt>.

=head1 COPYRIGHT

Copyright (C) 2014-2015 Steve Hay.  All rights reserved.

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
