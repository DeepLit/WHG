use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'HyperGlossary' }
BEGIN { use_ok 'HyperGlossary::Controller::Auth' }

ok( request('/auth')->is_success, 'Request should succeed' );


