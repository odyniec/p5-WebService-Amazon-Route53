use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Amazon::Route53',
    AUTHOR              => q{Michal Wojciechowski <odyniec@cpan.org>},
    VERSION_FROM        => 'lib/WebService/Amazon/Route53.pm',
    ABSTRACT_FROM       => 'lib/WebService/Amazon/Route53.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Digest::HMAC_SHA1' => 0,
        'LWP::UserAgent' => 0,
        'Test::More' => 0,
        'Tie::IxHash' => 0,
        'URI::Escape' => 0,
        'XML::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Amazon-Route53-*' },
);
