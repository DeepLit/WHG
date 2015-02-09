package HyperGlossary::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    ENCODING => 'utf-8',
    TEMPLATE_EXTENSION => '.tt2',
    CATALYST_VAR => 'Catalyst',
    INCLUDE_PATH => [
        HyperGlossary->path_to( 'root', 'templates' ),
        HyperGlossary->path_to( 'root', 'components' ),
        HyperGlossary->path_to( 'root', 'static' ),
        HyperGlossary->path_to( 'root', 'src' ),
        HyperGlossary->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => HyperGlossary->config->{wrapper}.'/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0
});


=head1 NAME

HyperGlossary::View::TT - TT View for HyperGlossary

=head1 DESCRIPTION

TT View for HyperGlossary. 

=head1 AUTHOR

=head1 SEE ALSO

L<HyperGlossary>

root

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
