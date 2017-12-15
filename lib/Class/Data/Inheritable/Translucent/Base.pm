#===============================================================================
#
# lib/Class/Data/Inheritable/Translucent/Base.pm
#
# DESCRIPTION
#   Abstract base class extending Class::Data::Inheritable::Translucent with
#   common functionality (initialize/reset methods) required by its Object and
#   Singleton subclasses.
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

package Class::Data::Inheritable::Translucent::Base;

use 5.008001;

use strict;
use warnings;

use parent qw(Class::Data::Inheritable::Translucent);

use Carp qw(carp croak);

#===============================================================================
# CLASS INITIALIZATION
#===============================================================================

our($VERSION);

BEGIN {
    $VERSION = '2.00';
}

__PACKAGE__->mk_object_accessor(__CDITB_initialized => 0);

#===============================================================================
# PUBLIC METHODS
#===============================================================================

#-------------------------------------------------------------------------------
# Object methods
#-------------------------------------------------------------------------------

#
# Overridable.
#
sub initialize {
    my($self, %args) = @_;
    croak("initialize() is an object method, not a class method") unless ref $self;

    # If the object has already been initialized (e.g. when called from reset())
    # then we must only (re-)initialize non-read-only attributes.
    my @attrs = $self->_get_editable_attrs();

    foreach my $attr (@attrs) {
        $self->$attr(delete $args{$attr}) if exists $args{$attr};
    }

    if (%args) {
        # Get a list of all attributes to distinguish read-only ones from
        # unknown ones.
        $self->_initializing(1);
        my %all_attrs = map { $_ => 1} $self->_get_editable_attrs();
        $self->_initializing(0);

        my @readonly_attrs;
        my @unknown_attrs;
        foreach my $attr (sort keys %args) {
            if (exists $all_attrs{$attr}) {
                push @readonly_attrs, $attr;
            }
            else {
                push @unknown_attrs, $attr;
            }
        }

        if (@readonly_attrs) {
            carp("initialize() ignored the following read-only attributes: " .
                 join(', ', map { "'$_'" } @readonly_attrs));
        }

        if (@unknown_attrs) {
            carp("initialize() ignored the following unknown attributes: " .
                 join(', ', map { "'$_'" } @unknown_attrs));
        }

        return 0;
    }

    return 1;
}

sub reset {
    my($self) = @_;
    croak("reset() is an object method, not a class method") unless ref $self;

    # Delete any non-read-only attributes set on this object.
    my @attrs = $self->_get_editable_attrs();
    my $attrs = $self->attrs();
    foreach my $attr (@attrs) {
        delete $attrs->{$attr};
    }

    # Reinitialize any non-read-only attributes.
    return $self->initialize();
}

#===============================================================================
# PROTECTED METHODS
#===============================================================================

#-------------------------------------------------------------------------------
# Object methods
#-------------------------------------------------------------------------------

#
# Overrides Class::Data::Inheritable::Translucent::_initialized().
#
sub _initialized {
    my $self = shift;
    return not exists $self->{__CDITB_initializing};
}

#
# Sets a private attribute in the object (sic; not the attributes hash returned
# by attrs()) indicating whether or not the object is currently initializing.
# This is intended to be set at the beginning of the constructor, immediately
# after creating the object body, and cleared just before returning from the
# constructor, just after initialization is complete.
#
sub _initializing {
    my($self, $flag) = @_;

    if ($flag) {
        $self->{__CDITB_initializing} = 1;
    }
    else {
        delete $self->{__CDITB_initializing};
    }
}

1;

__END__

#===============================================================================
# DOCUMENTATION
#===============================================================================

=head1 NAME

Class::Data::Inheritable::Translucent::Base - Add initialize/reset methods to Class::Data::Inheritable::Translucent

=head1 SYNOPSIS

See L<Class::Data::Inheritable::Translucent::Object> and
L<Class::Data::Inheritable::Translucent::Singleton>.

=head1 DESCRIPTION

This module is an abstract base class extending
L<Class::Data::Inheritable::Translucent> with common functionality
(initialize/reset methods) required by its
L<Class::Data::Inheritable::Translucent::Object> and
L<Class::Data::Inheritable::Translucent::Singleton> subclasses.

=head2 Object Methods

=over 4

=item C<initialize([ %args ])>

Sets the attributes of the invocant object from the given named parameter list
(hash) and returns 1.  If any given attributes are not object attributes or
translucent attributes of the class (or of any superclass) to which the
invocant object belongs, or if they are read-only and the object has already
been initialized, then they are ignored and initialize() will issue a warning
about them and return 0.

This method is called when constructing or cloning an object.  Subclasses may
override it to provide custom initialization, but it is not really intended to
be called directly.  In particular, if your object has read-only attributes then
initialize() will only be able to set them when it is called in the course of
constructing or cloning an object, but not if you call initialize() at a later
time, including when called via reset().

=item C<reset()>

Resets an object's non-read-only attributes to reveal their (translucent or
otherwise) class default values by deleting all such attributes from the object
and then calling initialize() with no arguments.

In the absence of any read-only attributes this has the effect of setting the
object to the same state as a new object constructed with a default constructor
call (i.e. new() with no arguments).

Read-only attributes, of course, cannot be reset so will be left unchanged.  If
initialize() has been overridden and is used to set any read-only attribute
values then it will emit a warning and return 0; otherwise it returns 1.

=back

=head1 DIAGNOSTICS

=head2 Warnings and Error Messages

This module may produce the following diagnostic messages.  They are classified
as follows (a la L<perldiag>):

    (W) A warning (optional).
    (F) A fatal error (trappable).
    (I) An internal error that you should never see (trappable).

=over 4

=item initialize() ignored the following read-only attributes: %s

(W) You passed some read-only attributes to a call to initialize() after the
object has been initialiazed (perhaps from via an override of initialize()
called from reset()).

=item initialize() ignored the following unknown attributes: %s

(W) You passed some attributes to initialize() (perhaps via new() or clone())
that are not object attributes or translucent attributes of the class (or of any
superclasses) to which the object being initialized (or constructed) belongs.

=item %s() is an object method, not a class method

(F) You tried to invoke the specified method on a class name, but it can only be
invoked on an object.

=back

=head1 SEE ALSO

L<Class::Data::Inheritable::Translucent::Object>,
L<Class::Data::Inheritable::Translucent::Singleton>,
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
