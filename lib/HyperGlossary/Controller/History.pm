package HyperGlossary::Controller::History;
use Moose;
use DBI;
use DBIx::MySperql qw(DBConnect SQLExec SQLFetch $dbh);
use WWW::HyperGlossary::Base;
use Encode;
use utf8;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

HyperGlossary::Controller::History - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller to retrieve history of edits. Still under development.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched HyperGlossary::Controller::History in History.');
}


sub auto : Private {
	my ($self, $c)                 = @_;
           
	   $dbh                        = $c->controller('Root')->_connect( $c->config->{hgdb} );
           if(!$c->user_exists()){

             $c->res->redirect($c->uri_for($c->controller('Auth')->action_for('login')));     
           }
           elsif(!$c->check_any_user_role( qw/ is_superuser is_content_admin/)){
             $c->res->redirect($c->uri_for($c->controller('Auth')->action_for('access_denied')));     
           }
        else{
	my $path                       = $c->request->path(); $path =~ s/\d+$//;
           
           $c->stash->{template}       = $path . '.tt2';
        }

}


sub getHist : Local {
	my ($self, $c) = @_;

	my $sql  =  "select category_id, category FROM hg_categories;";
	my ($categories) = SQLExec( $sql, '\@@' );
	$c->stash->{category_options}        = WWW::HyperGlossary::Base->_build_html_select_options( $categories, $c->stash->{category_id} );

	#$sql  =  "SELECT DISTINCT hg_users.user_id, last_name FROM hg_users, hg_definition_data WHERE hg_users.user_id = hg_definition_data.user_id AND hg_definition_data.definition_field_id = 13;";
	$sql  =  "SELECT hg_users.user_id, last_name FROM hg_users ORDER BY last_name ASC;";
	my ($users) = SQLExec( $sql, '\@@' );
	$c->stash->{user_options}        = WWW::HyperGlossary::Base->_build_html_select_options( $users);

}


sub listHist : Local {
	my ($self, $c) = @_;

	my $category_id	 	    	= $c->req->param('category_id');
	my $start_date	 	    	= $c->req->param('start_date') . " 00:00:00";
	my $end_date	 	    	= $c->req->param('end_date') . " 23:59:59";
	my $user_id	 	    	= $c->req->param('user_id');
	my $all_users	 	    	= $c->req->param('all_users');

	my $sql  =  "SELECT category FROM hg_categories WHERE category_id = $category_id;";
	my ($category) = SQLExec( $sql, '@' );
        
        $sql  =  "SELECT hg_category_words.category_word_id, hg_words.word_id, hg_words.word  FROM hg_words INNER JOIN hg_category_words ON ";
	$sql .=  "hg_words.word_id=hg_category_words.word_id where category_id='$category_id'";
        warn "GET WORDS: $sql";
	my ($words_ref) = SQLExec( $sql, '\@@' );
        
        my $dump = "<h1>$category</h1>\n";
        my $index=0; 
        foreach my $field (@$words_ref){
             $index++;   
             my ($category_word_id, $word_id, $word) = @$field;
             $dump .= "<h2>$index - $word</h2>\n";
	
             my ($history) 	    = $self->_get_hist_def( {all_users => $all_users, user_id => $user_id, cat_word_id => $category_word_id, word_id => $word_id, word => $word, category_id => $category_id, start_date => $start_date, end_date => $end_date} );
             
             $dump .= $history;

        }
        $c->stash->{'dump'} = $dump;
}


sub _get_hist_def : Private {
	my ( $self, $arg_ref )	      = @_;
	my $category_word_id 	      = $arg_ref->{'cat_word_id'};
	my $word 		      = $arg_ref->{'word'};
	my $category_id 	      = $arg_ref->{'category_id'};
	my $start_date 		      = $arg_ref->{'start_date'};
        my $end_date 	              = $arg_ref->{'end_date'};
        my $user_id 	              = $arg_ref->{'user_id'};
        my $all_users 	              = $arg_ref->{'all_users'};

	my $history;

	my $sql = "SELECT definition_field_id, field_label FROM hg_definition_fields WHERE category_id=$category_id";
	my $field_ref = SQLExec($sql, '\@@');

	foreach my $field (@$field_ref){
        	my ($field_id, $field_label) = @$field;
		
                $sql  = "SELECT b.data, b.definition_data_id, b.user_id, b.creation_date  FROM hg_definition_data b INNER JOIN hg_category_words_has_definition_data a ON b.definition_data_id=a.definition_data_id ";
                $sql .= "WHERE ";
                if($all_users eq ''){$sql .= "b.user_id = $user_id AND ";} 
                $sql .= "a.category_word_id=$category_word_id AND b.definition_field_id=$field_id AND creation_date > '$start_date' AND creation_date < '$end_date' ORDER BY creation_date DESC";
                warn "GET CURRENT DATA: $sql";
        	my($current_data, $definition_data_id, $current_user, $current_date) = SQLExec($sql, '@');
                if($current_date eq ''){next;}

                $current_data = WWW::HyperGlossary::Base->_html_unescape( $current_data );
                $current_data = decode("utf8",$current_data);
	warn "------> $word,$current_data, $definition_data_id, $current_user, $current_date";	
		$history .= "<br><b> $field_label last updated $current_date by user $current_user:</b><br>";
                if($current_data){$history .= $current_data;}else{$history .= "<p style='color:red'>NO DATA</p>";} 

                $sql  = "SELECT b.data, b.creation_date, user_id FROM hg_definition_data_history b INNER JOIN hg_data_has_history_data a ON b.definition_data_history_id=a.definition_data_history_id ";
                $sql .= "WHERE ";
                if($all_users eq ''){$sql .= "b.user_id = $user_id AND ";} 
                $sql .= "a.definition_data_id=$definition_data_id AND b.definition_field_id=$field_id AND creation_date > '$start_date' AND creation_date < '$end_date' ORDER BY creation_date ASC";
                warn "GET HISTORY DATA: $sql";
                my $data_ref = SQLExec($sql, '\@@');

                if(@$data_ref){$history .= "<h2> History for $field_label field for term $word</h2>\n";}

                foreach my $chunk (@$data_ref){
                        my ($data, $date, $user) = @$chunk;
                        $data = WWW::HyperGlossary::Base->_html_unescape( $data );
                        $data = decode("utf8",$data);
		
                        $history .= "<br><b> <h3>Edited on $date by user with ID: $user </h3></b><br>\n";
                        if($data ne ''){$history .= "<p>$data</p>\n";}else{$history.="<p style='color: red'>NO DATA</p>\n";}
                        $history .= "<hr COLOR='blue' NOSHADE>\n";
                }
                        $history .= "<hr COLOR='green' NOSHADE>\n";
        }

	return $history;
}

=head1 AUTHOR

Michael Bauer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

