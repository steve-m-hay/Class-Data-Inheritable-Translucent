#===============================================================================
#
# lib/Class/Data/Inheritable/Translucent/Singleton.pm
#
# DESCRIPTION
#   Abstract base class extending Class::Data::Inheritable::Translucent with a
#   singleton constructor method with separated initialization.
#
# COPYRIGHT
#   Copyright (C) 2015 Steve Hay.  All rights reserved.
#
# LICENCE
#   This module is free software; you can redistribute it and/or modify it under
#   the same terms as Perl itself, i.e. under the terms of either the GNU
#   General Public License or the Artistic License, as specified in the LICENCE
#   file.
#
#===============================================================================

package Class::Data::Inheritable::Translucent::Singleton;

use 5.008001;

use strict;
use warnings;

use Carp qw(croak);

my $singleton;
BEGIN {
    if (eval { require Apache::Singleton }) {
        $singleton = 'Apache::Singleton';
    }
    elsif (eval { require Class::Singleton }) {
        $singleton = 'Class::Singleton';
    }
    else {
        croak('Apache::Singleton or Class::Singleton is required for ' .
              'Class::Data::Inheritable::Translucent::Singleton');
    }
}

use parent (
    'Class::Data::Inheritable::Translucent::Base',
    $singleton
);

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

#
# Overrides (Apache|Class)::Singleton::instance();
#
sub instance {
    my($class, %args) = @_;
    croak("instance() is a class method, not an object method") if ref $class;
    croak("'$class' is an abstract base class") if $class eq __PACKAGE__;

    return $class->SUPER::instance(%args);
}

#===============================================================================
# PROTECTED METHODS
#===============================================================================

#-------------------------------------------------------------------------------
# Class methods
#-------------------------------------------------------------------------------

#
# Overrides (Apache|Class)::Singleton::_new_instance();
#
sub _new_instance {
    my($class, %args) = @_;

    my $self = $class->SUPER::_new_instance();

    $self->_initializing(1);

    # Initialize attributes with any (remaining) given arguments, overriding any
    # copied or translucent attributes in the process.
    $self->initialize(%args);

    $self->_initializing(0);

    return $self;
}

1;

__END__

#===============================================================================
# DOCUMENTATION
#===============================================================================

=head1 NAME

Class::Data::Inheritable::Translucent::Singleton - Add a singleton constructor method to Class::Data::Inheritable::Translucent

=head1 SYNOPSIS

    package Baz;
    use parent qw(Class::Data::Inheritable::Translucent::Singleton);

    Baz->mk_object_accessor(attr => 0);

    # Class constructor
    my $obj1 = Baz->instance(attr => 1);
    my $obj2 = Baz->instance(attr => 2); # same object as $obj1

    # Object reset
    $obj1->reset(); # $obj1 and $obj2 now both have attr == 0

    package Baz2;
    use parent qw(Baz);

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
L<Class::Data::Inheritable::Translucent> with a singleton constructor method
with separated initialization.  The objects constructed are simple hash-based
objects compatible with the accessor methods installed by
Class::Data::Inheritable::Translucent.

The singleton design pattern behaviour is inherited from either
Apache::Singleton or Class::Singleton, whichever is found first (looking in that
order); an exception will be thrown if neither is available.  Apache::Singleton
is more flexible since it allows one instance per request when run in a mod_perl
environment (but still permits only one instance per process otherwise).

Attributes may be initialized by the constructor, either explicitly, or via a
separated initialize() method.  A reset() method can be used to restore the
object's non-read-only attributes to their default values (translucent or
otherwise).

Note that all of these methods, just like the accessor methods created by
L<Class::Data::Inheritable::Translucent>, only perform shallow copies of
attribute values.

=head2 Class Methods

=over 4

=item C<instance([ %args ])>

Constructs the single instance of the invocant class and returns it.  The object
will be a simple hash-based object compatible with the accessor methods
installed by Class::Data::Inheritable::Translucent.

The new object can optionally be initialized from a named parameter list (hash)
of attributes.

=back

=head2 Object Methods

=over 4

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

=item Apache::Singleton or Class::Singleton is required for
      Class::Data::Inheritable::Translucent::Singleton

(F) You tried to use Class::Data::Inheritable::Translucent::Singleton but you do
not have either Apache::Singleton or Class::Singleton available.

=item %s() is a class method, not an object method

(F) You tried to invoke the specified method on an object, but it can only be
invoked on a class name.

=item '%s' is an abstract base class

(F) You tried to construct an instance of the specified class, but it is an
abstract base class, i.e. it cannot be instantiated.

=back

=head1 EXPORTS

I<None>.

=head1 KNOWN BUGS

I<None>.

=head1 SEE ALSO

L<Class::Data::Inheritable::Translucent::Object>,
L<Class::Data::Inheritable::Translucent>.

=head1 AUTHOR

Steve Hay E<lt>L<shay@cpan.org|mailto:shay@cpan.org>E<gt>.

=head1 COPYRIGHT

Copyright (C) 2015 Steve Hay.  All rights reserved.

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
