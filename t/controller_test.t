use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'HyperGlossary' }
BEGIN { use_ok 'HyperGlossary::Controller::test' }

ok( request('/test')->is_success, 'Request should succeed' );


