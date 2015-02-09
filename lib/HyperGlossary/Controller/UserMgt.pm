package HyperGlossary::Controller::UserMgt;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use CGI::Browse;
use Data::Dumper;

#use Digest::SHA qw(sha256);

=head1 NAME

HyperGlossary::Controller::UserMgt - Catalyst Controller

=head1 DESCRIPTION

Catalyst user management Controller.

=head1 METHODS

=cut


=head2 base

=cut
sub auto : Private {
	my ($self, $c)                 	= @_;
	my $path                       	= $c->request->path(); $path =~ s/\d+$//;
	$c->stash->{template}		= $path . '.tt2';
}

sub base : Chained('/'): PathPart('usermgt'): CaptureArgs(0) {
	my ($self, $c) = @_;
	$c->stash(users_rs => $c->model('hgDB::HgUsers'));
	$c->stash(roles_rs => $c->model('hgDB::HgRoles'));
	my $users_rs = $c->stash->{users_rs};

#warn "DUMP!!!!! " . Dumper($users_rs);
}
	

=head2 add

add action - Add user to the system

=cut
sub add : Chained('base'): PathPart('add'): Args(0) {
	my ($self, $c) = @_;
	
	if($c->user_exists() && $c->check_user_roles( qw/ can_add_user is_user_admin is_superuser/)){
		$c->stash(columns=> [
					{id=>'first_name',	name=>'First Name'},
					{id=>'last_name',	name=>'Last Name'},
					{id=>'uname',		name=>'User Name'},
					{id=>'email',		name=>'Email'},
					{id=>'password',	name=>'Password'}
			      	]
		    	);
		    
		if(lc $c->req->method eq 'post') {
			my $params = $c->req->params;

			my $users_rs = $c->stash->{users_rs};


			my $newuser = eval {$users_rs->create({
				first_name	=> $params->{first_name},
				last_name	=> $params->{last_name},
				user_name 	=> $params->{uname},
				email 		=> $params->{email},
				user_pass 	=> $params->{password},
			})};

			if($@) {
				$c->log->debug(
					"User tried to sign up with an invlid email address, redoing...");
				$c->stash(errors => {email => 'invalid'}, err => $@);
				return;
			}
			return $c->res->redirect($c->uri_for( 
				$c->controller('UserMgt')->action_for('profile'),{user_id=>$newuser->user_id})) ;
		}
	}
	else{
		$c->detach($c->controller('Auth')->action_for('access_denied'));
	}
}


=head2 user

user action - Base page that displays the about message.

=cut
sub user : Chained('base'): PathPart(''): CaptureArgs(0) {
	my ($self, $c,$test) = @_;

my $userid = $c->request->param('user_id');
my $uid = $c->request->param('id');

	my $user = $c->stash->{users_rs}->find({user_id	=> $userid},
					       {key 	=> 'primary'});
	foreach my $col ($c->stash->{users_rs}->result_source->columns){
	
#warn Dumper($user->$col) . '*****************************' . Dumper($c->user->id);
}

	die "No such user" if(!$user);

	$c->stash(user => $user);
}

sub profile : Chained('user') :PathPart('profile'): Args(0) {
	my ($self, $c) = @_;

	$c->stash->{template} = 'usermgt/profile.tt2';
}

=head2 edit

edit action - edit an existing users data

=cut
sub edit : Chained('user') :PathPart('edit'): Args(0) {
	my ($self, $c) = @_;

	if((lc $c->req->method eq 'post') || (lc $c->req->method eq 'get')) {
		my $params 	= $c->req->params;
		my $user 	= $c->stash->{user};

	warn 'USER ID: '.Dumper($user->id)."\n";
		warn 'USER ID: '.Dumper($c->user->user_id)."\n";
		if($c->user->user_id != $user->id){ 
			$c->stash->{message}="Malicious attempt to update another user by: ". $c->user->user_name;
			$c->detach($c->controller('Auth')->action_for('access_denied'));
		}
		else{
			$user->update({
				email		=> $params->{email},
				user_pass	=> $params->{password},
			});
			return $c->res->redirect($c->controller('UserMgt')->action_for('profile'), {user_id=>$user->user_id} ) ;
		}

	}
}	

=head2 set_roles

set_roles action - Set the roles of the user

=cut
sub set_roles :Chained('user') :PathPart('set_roles'): Args() {
	my ($self, $c) = @_;
	
	my $user 	= $c->stash->{user};
	if(lc $c->req->method eq 'post'){
		my @roles = $c->req->param('role');

		$user->set_all_roles(@roles);
	}
	
		return $c->res->redirect($c->uri_for( 
			$c->controller('UserMgt')->action_for('profile'),{user_id=>$user->user_id})) ;

}


=head2 list

List action - List users

=cut
sub list : Chained('base') :PathPart('list'): Args(0) {
	my ($self, $c) = @_;
	my %list_vars;
        my $status;
   	
        if(!defined $c->req->param('status') && $c->session->{status}){$status = $c->session->{'status'};}
   	elsif($c->req->param('status')){$status = $c->req->param('status');$c->session->{status} = $c->req->param('status')}
   	else{ $c->session->{status} = 'active';$status = 'active'}
   	
        if(!defined $c->req->param('index') && $c->session->{index}){$list_vars{index} = $c->session->{'index'};}
   	elsif($c->req->param('index')){$list_vars{index} = $c->req->param('index');$c->session->{index} = $c->req->param('index')}
   	else{ $c->session->{index} = 0;}

   	if(!defined $c->req->param('window') && $c->session->{window}){$list_vars{window} = $c->session->{'window'};}
   	elsif($c->req->param('window')){$list_vars{window} = $c->req->param('window');$c->session->{window} = $c->req->param('window')}
   	else{ $c->session->{window} = 20;}
   
	$c->session->{sort} = '';
   	if(!defined $c->req->param('sort') && $c->session->{sort}){$list_vars{sort} = $c->session->{'sort'};}
   	elsif($c->req->param('sort')){$list_vars{sort} = $c->req->param('sort');$c->session->{sort} = $c->req->param('sort')}
   	else{ $c->session->{sort} = '';}
   	
   
   	if(!defined $c->req->param('sort_vec') && $c->session->{sort_vec}){$list_vars{sort_vec} = $c->session->{'sort_vec'};}
   	elsif($c->req->param('sort_vec')){$list_vars{sort_vec} = $c->req->param('sort_vec');$c->session->{sort_vec} = $c->req->param('sort_vec')}
   	else{ $c->session->{sort_vec} = 'asc';}
   
# Create browse object
	my $fields      = [ { name   => 'user_id', 		label => 'ID',            	hide => 1, sort => 0 },
         	            { name   => 'first_name',           label => 'Fisrt Name',         	hide => 0, sort => 1 },
                	    { name   => 'last_name',   		label => 'Last Name',     	hide => 0, sort => 1 },
                   	    { name   => 'email',          	label => 'Email',       	hide => 0, sort => 1 },
                   	    { name   => 'user_name',            label => 'User Name',         	hide => 0, sort => 1 , link => 'profile_link'},
                   	    { name   => 'status',            	label => 'Toggle Status',       hide => 0, sort => 1 , link => 'status_link'} ];

	my $params      = { fields   => $fields,
        	            sql      => "select user_id, first_name, last_name, email, user_name, status from hg_users WHERE status='$status'",
                	    connect  => { %{$c->config->{hgdb}} },
            		    urls     => { root => $c->config->{rootURL}, 
                                          browse => $c->controller()->action_for('list'), 
                                          profile_link => $c->controller('UserMgt')->action_for('profile').'?user_id=', 
                                          status_link => $c->controller('UserMgt')->action_for('status')."?status=$status&user_id=", 
                                          delete => $c->controller()->action_for('delete').'?user_id=' },
                    	    classes  => ['browseRowA', 'browseRowA', 'browseRowA', 'browseRowB', 'browseRowB', 'browseRowB'],
                    	    features => { default_html => 1, delete => 'each' },
                    	    #features => { default_html => 1, delete => 'multi' },
                  	 };
			 
	my $browse      = CGI::Browse->new( $params );

	$c->stash->{list} = $browse->build(\%list_vars);
        if($status eq 'active'){$c->stash->{active_selected} = 'selected';}
        if($status eq 'inactive'){$c->stash->{inactive_selected} = 'selected';}

}

=head2 delete

Delete action - Delete a user

=cut
sub delete :Chained('user') :PathPart('delete'): Args() {
	my ($self, $c) = @_;
	
	if($c->user_exists() && $c->check_user_roles( qw/ can_delete_user /)){
		my $user 	= $c->stash->{user};
		$user->delete();
		return $c->res->redirect( $c->uri_for('list') );
	}
	else {
		$c->detach($c->controller('Auth')->action_for('access_denied'));
	}

}

=head2 status

Status action - Toggle the status of a user between active and inactive

=cut
sub status :Chained('user') :PathPart('status'): Args() {
	my ($self, $c) = @_;
	my $current_status = $c->req->param('status');

	if($c->user_exists() && $c->check_user_roles( qw/ can_delete_user /)){
		my $user 	= $c->stash->{user};
	
                if($current_status eq 'active'){ $user->update({status	=> 'inactive'});}
                if($current_status eq 'inactive'){ $user->update({status	=> 'active'});}

		return $c->res->redirect( $c->uri_for('list') );
	}
	else {
		$c->detach($c->controller('Auth')->action_for('access_denied'));
	}

}
=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
