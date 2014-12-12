#!perl

use 5.008001;

use strict;
use warnings;

use Test::More;
plan skip_all => 'Author testing only' unless $ENV{AUTHOR_TESTING};
eval { require Test::Pod; Test::Pod->import() };
plan skip_all => "Test::Pod required for testing POD" if $@;
plan skip_all => "Test::Pod 1.14 required for testing POD" if $Test::Pod::VERSION < 1.14;
all_pod_files_ok();
