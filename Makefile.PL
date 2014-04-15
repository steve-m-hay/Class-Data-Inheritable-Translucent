use strict;
use warnings;
no warnings 'numeric';
use ExtUtils::MakeMaker;

my @extras = ();

push(@extras,
     ABSTRACT_FROM => 'lib/Class/Data/Inheritable/Translucent.pm',
     AUTHOR        => 'Ryan McGuigan, Steve Hay (shay@cpan.org)')
    if ($ExtUtils::MakeMaker::VERSION >= 5.4301);
     
push(@extras,
     LICENSE       => 'perl')
    if ($ExtUtils::MakeMaker::VERSION >= 6.3001);

WriteMakefile(
    NAME                => 'Class::Data::Inheritable::Translucent',
    VERSION_FROM        => 'lib/Class/Data/Inheritable/Translucent.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    @extras
);
