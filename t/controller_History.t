use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'HyperGlossary' }
BEGIN { use_ok 'HyperGlossary::Controller::History' }

ok( request('/history')->is_success, 'Request should succeed' );
done_testing();
