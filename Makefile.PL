#!perl
#===============================================================================
#
# Makefile.PL
#
# DESCRIPTION
#   Makefile creation script.
#
# COPYRIGHT
#   Copyright (C) 2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use ExtUtils::MakeMaker 6.64;
use ExtUtils::MakeMaker qw(WriteMakefile);

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    WriteMakefile(
        NAME          => 'Class::Data::Inheritable::Translucent',
        ABSTRACT_FROM => 'lib/Class/Data/Inheritable/Translucent.pm',
        AUTHOR        => 'Ryan McGuigan, Steve Hay <shay@cpan.org>',
        LICENSE       => 'perl_5',
        VERSION_FROM  => 'lib/Class/Data/Inheritable/Translucent.pm',

        META_MERGE => {
            'meta-spec' => {
                version => 2
            },

            resources => {
                repository => 'https://github.com/steve-m-hay/Class-Data-Inheritable-Translucent'
            }
        },

        MIN_PERL_VERSION => '5.008001',

        CONFIGURE_REQUIRES => {
            'ExtUtils::MakeMaker' => '6.64',
            'strict'              => 0,
            'warnings'            => 0
        },

        TEST_REQUIRES => {
            'Test::More'          => 0,
          # 'Test::Pod'           => '1.14', # Only required for POD testing
          # 'Test::Pod::Coverage' => '1.04', # Only required for POD testing
            'base'                => 0,
            'constant'            => 0,
            'strict'              => 0,
            'warnings'            => 0
        },

        PREREQ_PM => {
          # 'Sub::Name'           => 0,      # Recommended
            'strict'              => 0,
            'warnings'            => 0
        },

        dist => {
            PREOP   => 'find $(DISTVNAME) -type f -print|xargs chmod 0644 && ' .
                       'find $(DISTVNAME) -type d -print|xargs chmod 0755',
            TO_UNIX => 'find $(DISTVNAME) -type f -print|xargs dos2unix'
        }
    );
}

#===============================================================================
