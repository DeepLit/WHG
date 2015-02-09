package HyperGlossary::Controller::Auth;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use Mail::Builder::Simple;
use Data::Dumper;
use DateTime;

=head1 NAME

HyperGlossary::Controller::Auth - Catalyst Controller

=head1 DESCRIPTION

Action to handle HyperGLossary authentication.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched HyperGlossary::Controller::Auth in Auth.');
}

=head2 login ( .admin/login)

User login action

=cut

sub login : Local : Args(0) {
	my ($self, $c)        = @_; 
	$c->stash->{template} = 'auth/login.tt2';

	if( exists($c->req->params->{'username'}) ) {
                my $user = $c->model('hgDB::HgUsers')->find({user_name => $c->req->params->{'username'}});
		if( $c->authenticate( {
			user_name => $c->req->params->{'username'},
			user_pass => $c->req->params->{'userpass'},
			status	  => ['active','trial']
			}) )
		{ 
                        $user->update({last_success    => DateTime->now(time_zone => 'America/Chicago')});

			$c->stash->{'message'} = "Your are now logged in.";
			$c->response->redirect($c->uri_for($c->controller('hg')->action_for('url')) );
			$c->detach();
			return;
		}
		else {
                        if($user){
                          $user->update({failed_login_1  => DateTime->now(time_zone => 'America/Chicago')});
                        }
			$c->stash->{'message'} = "Invalid login.";
		}
    	}	
			
}

=head2 login ( .admin/logout)

User logout  action

=cut

sub logout : Local : Args(0) {
	my ($self, $c)        = @_; 
	$c->stash->{template} = 'auth/logout.tt2';

	$c->logout();
	$c->stash->{'username'} = 'Guest';
	$c->stash->{'message'} = "You have been logged out.";

}

=head2 access_denied ( .admin/access_denied)

Message deplayed when an action the is accessed for which the user does not have permission

=cut
sub access_denied : Local : Args(0) {
	my ($self, $c)        = @_; 
	$c->stash->{template} = 'auth/accessdenied.tt2';

	$c->stash->{'message'} = "You do not have permission for that action!";

}

=head2 request_accountn ( .admin/request_account)

email request account action

=cut
sub request_account : Local : Args(0) {
	my ($self, $c)        = @_; 

	$c->stash->{template} = 'auth/requestaccount.tt2';

}

=head2 email_request ( .admin/email_request)

email request account action

=cut
sub email_request : Local : Args(0) {
	my ($self, $c)        = @_; 

	my $params = $c->req->params;
        my $text = "First Name: $params->{first_name}\n Last Name: $params->{last_name}\n Email Address: $params->{email}\n Affliation: $params->{affiliation}";

        my $mail = Mail::Builder::Simple->new;

        $mail->send(
                from            => 'HyperGlossary@'.$c->config->{domain},
                to              => $c->config->{email},
                subject         => 'HG Account Request',
                plaintext       => $text
        );

        $c->stash->{template} = 'auth/message.tt2';
	$c->stash->{'message'} = "An account request has been sent to the administrator and you should recieve an email soon with a username and password.";
}
=head1 AUTHOR

Michael Anton Bauer <mbkodos@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
