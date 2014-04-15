use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::Data::Inheritable::Translucent',
    AUTHOR              => 'Ryan McGuigan <ryan@cardweb.com>',
    VERSION_FROM        => 'lib/Class/Data/Inheritable/Translucent.pm',
    ABSTRACT_FROM       => 'lib/Class/Data/Inheritable/Translucent.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-Data-Inheritable-Translucent-*' },
);
