#!perl

use 5.008001;

use strict;
use warnings;

use Test::More;
plan skip_all => 'Author testing only' unless $ENV{AUTHOR_TESTING};
eval { require Test::Pod::Coverage; Test::Pod::Coverage->import() };
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $Test::Pod::Coverage::VERSION < 1.04;
all_pod_coverage_ok();
