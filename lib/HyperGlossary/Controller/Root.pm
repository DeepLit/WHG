package HyperGlossary::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use DBI;
use DBIx::MySperql qw(DBConnect SQLExec SQLFetch $dbh);

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

HyperGlossary::Controller::Root - Root Controller for HyperGlossary

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut


=head2 auto

Auto action - builds the left navigation side bar depending on th user that is logged in. 
Automatically runs befor all other actions

=cut

sub auto : Private {
	my ($self, $c)                 = @_;

        my ($active_url,$active_text, $active_mgt, $active_acct, $active_abt);
        if($c->request->path eq 'hg/url'){$active_url = 'active';}else{$active_url = '';}
        if($c->request->path eq 'hg/text'){$active_text = 'active';}else{$active_text = '';}
        if($c->request->path eq 'hg/about'){$active_abt = 'active';}else{$active_abt = '';}
        if($c->request->path eq 'contentmgt/wordMgt'){$active_mgt = 'active';}else{$active_mgt = '';}
        if($c->request->path eq 'usermgt/list'){$active_acct = 'active';}else{$active_acct = '';}

        #Need to build nav depending on who is logged in.
	#my $nav  = "<ul class='nav nav-pills nav-stacked' >";
	my  $nav .=	"<li class='$active_url'><a href=\'".$c->config->{rootURL}."hg/url\'>Submit URL</a></li>";
	   $nav .=	"<li class='$active_text'><a href=\'".$c->config->{rootURL}."hg/text\'>Submit Text</a></li>";
	        if($c->user_exists() && $c->check_any_user_role( qw/ is_superuser can_edit_def can_add_word /)){
	                $nav .=	"<li class='$active_mgt'><a href=\'".$c->config->{rootURL}."contentmgt/wordMgt\'>Word Mgmt</a></li>";
                }
	        if($c->user_exists() && $c->check_user_roles( qw/ can_add_user is_user_admin is_superuser /)){
	                $nav .=	"<li class='$active_acct'><a href=\'".$c->config->{rootURL}."usermgt/list\'>Account  Mgmt</a></li>";
                }
	   $nav .=	"<li class='$active_abt'><a href=\'".$c->config->{rootURL}."hg/about\'>About HG</a></li>";
	#   $nav .= "</ul>";
	$c->stash->{nav} 	= $nav;
	
        if($c->user()){$c->stash->{'username'} = $c->user->get('user_name');}else{$c->stash->{'username'} = 'Guest';}
}

=head2 index

Index action - Base page that displays the about message.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'hg/about.tt2';
    $c->detach('/hg/about');
}

=head2 default (global)

Default action - display the error page (message.tt), for example when a
nonexistent action was requested.

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( '<h1>Sorry no such page</h1>' );
    $c->response->status(404);
}


=head2 _connect

Estblishes the connection to the database using the credentials found in the conf/hyperglossary.yml file

=cut

sub _connect {
        my ( $self, $parameters ) = @_;
        return &DBConnect( %{ $parameters } );
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
