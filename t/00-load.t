#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Bootstrap' );
}

diag( "Testing App::Bootstrap $App::Bootstrap::VERSION, Perl $], $^X" );
