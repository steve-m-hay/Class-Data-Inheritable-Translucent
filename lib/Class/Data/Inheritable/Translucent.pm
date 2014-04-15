package Class::Data::Inheritable::Translucent;

use strict;
use warnings;

=head1 NAME

Class::Data::Inheritable::Translucent - Inheritable, overridable, translucent
class data / object attributes

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  package Foo;
  use base 'Class::Data::Inheritable::Translucent';

  Foo->mk_translucent("bar");
  Foo->bar("baz");

  $obj = Foo->new;

  print $obj->bar; # prints "baz"

  $obj->bar("whatever");

  print $obj->bar; # prints "whatever"
  print Foo->bar;  # prints "baz"

  $obj->bar(undef);

  print $obj->bar; # prints "baz"

=head1 DESCRIPTION

This module is derived from Class::Data::Inheritable, and is largely the same,
except the class data accessors double as translucent object attributes.

Object data, by default, is stored in $obj->{$attribute}.  See the ->attrs
method, explained below, on how to change that.

=head1 METHODS

=over

=item B<mk_translucent>

Creates inheritable class data / translucent instance attributes

=cut

sub mk_translucent {
    no strict 'refs';

    my ($declaredclass, $attribute, $data) = @_;

    my $accessor = sub {
        my $obj = ref($_[0]) ? $_[0] : undef;
        my $wantclass = ref($_[0]) || $_[0];

        return $wantclass->mk_translucent($attribute)->(@_)
          if @_>1 && $wantclass ne $declaredclass;

        if ($obj) {
            my $attrs = $obj->attrs;
            $attrs->{$attribute} = $_[1] if @_ > 1;
            return $attrs->{$attribute} if defined $attrs->{$attribute};
        }
        else {
            $data = $_[1] if @_>1;
        }
        return $data;
    };

    my $alias = "_${attribute}_accessor";
    *{$declaredclass.'::'.$attribute} = $accessor;
    *{$declaredclass.'::'.$alias}     = $accessor;
}

=pod

=item B<attrs>

This method is called by the generated accessors and, by default, simply
returns the object that called it, which should be a hash reference for storing
object attributes.  If your objects are not hashrefs, or you wish to store your
object attributes in a different location, eg. $obj->{attrs}, you should
override this method.  Class::Data::Inheritable::Translucent stores object
attributes in $obj->attrs->{$attribute}.

=cut

sub attrs {
    my $obj = shift;
    $obj->{attrs} = {} unless defined $obj->{attrs};
    return $obj->{attrs};
}

=pod

=back

=head1 AUTHOR

Ryan McGuigan, <ryan@cardweb.com>

Derived from Class::Data::Inheritable, originally by Damian Conway

=head1 ACKNOWLEDGEMENTS

Thanks to Damian Conway for L<Class::Data::Inheritable>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Ryan McGuigan, all rights reserved.

mk_translucent is derived from mk_classdata from Class::Data::Inheritable,
Copyright Damian Conway and Michael G Schwern, licensed under the terms of the
Perl Artistic License.

This program is free software; It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
L<http://www.perl.com/perl/misc/Artistic.html>)

=head1 BUGS

Please report any bugs or feature requests to ryan@cardweb.com.

=head1 SEE ALSO

=over 2

=item *

L<Class::Data::Inheritable>

=item *

L<perltooc> - Tom's OO Tutorial for Class Data in Perl - a pretty nice Class
Data tutorial for Perl

=item *

The source.  It's quite short, and simple enough.

=back

=cut

1; # End of Class::Data::Inheritable::Translucent
