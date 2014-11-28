#!perl -T

use 5.008001;

use strict;
use warnings;

use Test::More tests => 19;

package Ray;
use base qw(Class::Data::Inheritable::Translucent);
Ray->mk_class_accessor('Ubu');
Ray->mk_class_accessor(DataFile => '/etc/stuff/data');
Ray->mk_ro_class_accessor(ro => 'readonly');

package Gun;
use base qw(Ray);
Gun->Ubu('Pere');

package Suitcase;
use base qw(Gun);
Suitcase->DataFile('/etc/otherstuff/data');

package main;

foreach my $class (qw/Ray Gun Suitcase/) { 
	can_ok $class => 
		qw/mk_class_accessor Ubu _Ubu_accessor DataFile _DataFile_accessor/;
}

# Test that superclasses effect children.
is +Gun->Ubu, 'Pere', 'Ubu in Gun';
is +Suitcase->Ubu, 'Pere', "Inherited into children";
is +Ray->Ubu, undef, "But not set in parent";

# Set value with data
is +Ray->DataFile, '/etc/stuff/data', "Ray datafile";
is +Gun->DataFile, '/etc/stuff/data', "Inherited into gun";
is +Suitcase->DataFile, '/etc/otherstuff/data', "Different in suitcase";

# Now set the parent
ok +Ray->DataFile('/tmp/stuff'), "Set data in parent";
is +Ray->DataFile, '/tmp/stuff', " - it sticks";
is +Gun->DataFile, '/tmp/stuff', "filters down to unchanged children";
is +Suitcase->DataFile, '/etc/otherstuff/data', "but not to changed";


my $obj = bless {}, 'Gun';
eval { $obj->mk_class_accessor('Ubu') };
ok $@ =~ /^mk_class_accessor\(\) is a class method, not an object method/,
"Can't create class accessor for an object";

is $obj->DataFile, "/tmp/stuff", "But objects can access the data";

is(Gun->ro, "readonly", "readonly attribute Ok thru class");
is($obj->ro, "readonly", "readonly attribute Ok thru object");
eval { Gun->ro(2) };
ok $@ =~ /^'ro' is a read-only attribute/,
   "readonly attribute can't be written thru class";
eval { $obj->ro(2) };
ok $@ =~ /^'ro' is a read-only attribute/,
   "readonly attribute can't be written thru object";
