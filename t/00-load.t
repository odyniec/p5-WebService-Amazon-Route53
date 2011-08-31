#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Amazon::Route53' ) || print "Bail out!
";
}

diag( "Testing WebService::Amazon::Route53 $WebService::Amazon::Route53::VERSION, Perl $], $^X" );
