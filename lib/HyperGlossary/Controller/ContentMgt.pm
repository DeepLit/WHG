package HyperGlossary::Controller::ContentMgt;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use WWW::HyperGlossary::Base;
use WWW::HyperGlossary::SAXchemeddlHandler;
use XML::Parser::PerlSAX;
use WWW::HyperGlossary;
use DBI;
use DBIx::MySperql qw(DBConnect SQLExec SQLFetch $dbh);
use Data::Dumper;
use Text::Demoroniser qw(demoroniser demoroniser_utf8);
use Encode;
use String::Random;
use utf8;
#use encoding "iso 8859-7";



=head1 NAME

HyperGlossary::Controller::ContentMgt - Catalyst Controller

=head1 DESCRIPTION

Catalyst Glossary Content Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched HyperGlossary::Controller::ContentMgt in ContentMgt.');
}

sub auto : Private {
	my ($self, $c)                 = @_;
           
           if(!$c->user_exists() || !$c->check_any_user_role( qw/ is_superuser can_edit_def can_add_word is_content_admin/)){
             $c->res->redirect($c->uri_for($c->controller('Auth')->action_for('login')));     
           }

	my $path                       = $c->request->path(); $path =~ s/\d+$//;
           
           $c->stash->{template}       = $path . '.tt2';
	   $dbh                        = $c->controller('Root')->_connect( $c->config->{hgdb} );
}

#Controller (Form Validation) Check if term is already in glossary
sub checkTermExists :Local {
	my ($self, $c) = @_;
	
        my $word	     	      = $c->req->param('word');
	my $category_id	     	      = $c->req->param('category_id');
        
        my $category_word_id;

        my $sql = "SELECT word_id FROM hg_words WHERE word = '$word'";
	my ($word_id) = SQLExec( $sql, '@' );

        if($word_id){
            $sql = "SELECT category_word_id FROM hg_category_words WHERE word_id = $word_id AND category_id = $category_id";
            ($category_word_id) = SQLExec( $sql, '@' );
        }else{$c->stash->{'success'} = 1;}
        if($category_word_id){
                $c->stash->{'success'} = 0;
        }else{$c->stash->{'success'} = 1;}

}


#Controller for Word Management
sub wordMgt :Local {
	my ($self, $c) = @_;
	
	$c->stash->{jsFiles}	 	= ['static/js/dynaform/Ext.form.Field.js','static/js/dynaform/Ext.form.FieldSet.js','static/js/dynaform/Ext.form.FormPanel.js','static/js/livegrid/build/livegrid-all-debug.js','static/js/tiny_mce/tiny_mce_src.js','static/js/Ext.ux.TinyMCE.js', 'static/js/gridForm.js'];
	$c->stash->{'title'}	      	= 'Word Management';
	$c->view('TT');
}

#returns JSON object of the glossaries in the database
sub getCategory : Local {
	my ($self, $c) = @_;

	my $sql  =  "select category_id, category, editable, active FROM hg_categories";
	if(! $c->check_user_roles( qw/ is_user_admin is_superuser /)){
                $sql .= " WHERE active = 1";
        }
	my ($categories) = SQLExec( $sql, '\@@' );
	
	my @catList=();
	foreach my $category ( @$categories ) {
		my ( $cat_id, $cat, $editable, $active) = @$category;
		push(@catList, {id=>$cat_id,category=>$cat,editable=>$editable, active=>$active});
	}
	
    	$c->stash->{'json_cats'} = \@catList;
    	$c->detach($c->view('JSON'));
}

#returns JSON object containg the words of the selected glossary from the database
sub getWord : Local {
	my ($self, $c) = @_;

	my $category	 	    	= $c->req->param('cat');
	my $start	 	    	= $c->req->param('start');
	my $limit	 	    	= $c->req->param('limit');
	my $sort	 	    	= $c->req->param('sort');
	my $direction	 	    	= $c->req->param('dir');
	
	my $sqlCount  =  "SELECT COUNT(hg_words.word_id)  FROM hg_words INNER JOIN hg_category_words ON ";
	   $sqlCount .=  "hg_words.word_id=hg_category_words.word_id where category_id='$category'";
	my ($total) = SQLExec( $sqlCount, '@' );

	my $sql  =  "SELECT hg_category_words.category_word_id, hg_words.word, hg_words.word_id, hg_category_words.word_type_id FROM hg_words INNER JOIN hg_category_words ON ";
	   $sql .=  "hg_words.word_id=hg_category_words.word_id where category_id='$category' ORDER BY $sort $direction LIMIT $start, $limit;";
           warn "GET WORDS: $sql";
	my ($words) = SQLExec( $sql, '\@@' );

	my @wordList=();
	foreach my $word ( @$words ) {
		my ( $category_word_id, $word, $word_id, $wordtype) = @$word;
               #warn "BFORE ======> $word\n"; 
                $word = WWW::HyperGlossary::Base->_html_unescape( $word );
               #warn "AFTER UNESCAPE ======> $word\n"; 
                #$word = demoroniser($word);
                $word = decode("utf8",$word);
               #warn "AFTER DEMORONISER ======> $word\n"; 
                #$word = Encode::decode('UTF-8', $word);
               #warn "AFTER ENCODE DECODE======> $word\n"; 
                
                $sql = "SELECT word_type_id, word_type FROM hg_word_types WHERE word_type_id = $wordtype";
                my($word_type_id, $word_type) = SQLExec($sql, '@');
		push(@wordList, {cat_word_id=>$category_word_id,word_id=>$word_id,word=>$word,word_type_id=>$word_type_id,word_type=>$word_type});
	}
    	$c->stash->{'json_words'} = \@wordList;
	$c->stash->{json_version}=1;	
	$c->stash->{json_totalCount}=$total;	
    	$c->detach($c->view('JSON'));
}

sub definition : Local{
	my ( $self, $c )              = @_;

	my @infoList=();
	my $word_id	     	      = $c->req->param('word_id');
	my $category_word_id	      = $c->req->param('cat_word_id');
	my $word	     	      = $c->req->param('word');
	my $category_id	     	      = $c->req->param('cat');

	my ($definition) 	      = $self->_get_def( {cat_word_id => $category_word_id, word_id => $word_id, category_id => $category_id} );
	
        my $sql = "SELECT hg_category_words.word_type_id, word_type FROM hg_word_types,hg_category_words WHERE hg_category_words.word_type_id = hg_word_types.word_type_id AND hg_category_words.category_word_id = $category_word_id";
        my($word_type_id, $word_type) = SQLExec($sql, '@');

	push(@infoList, {word=>$word, cat_word_id=>$category_word_id, category_id=>$category_id, word_id=>$word_id, definition=>$definition,word_type_id=>$word_type_id,word_type=>$word_type});
	$c->stash->{'json_info'}=\@infoList;	
    	$c->detach($c->view('JSON'));
}

sub def : Local{
	my ( $self, $c )              = @_;

	my @infoList=();
	my $w_id	     	      = $c->req->param('id');
	my $cat_id	     	      = $c->req->param('cat');
	my ($word, $word_id, $category_id, $definition) = $self->_get_def( {word_id => $w_id, category_id => $cat_id} );
	
	push(@infoList, {word=>$word, word_id=>$word_id, definition=>$definition});
	$c->stash->{json_info}=\@infoList;	
    	$c->detach($c->view('JSON'));
}

#reordView: Builds view of a glossary record 
sub recordView : Local{
	my ( $self, $c )              	= @_;

	my $word_id	     	      	= $c->req->param('word_id');
	my $category_word_id	     	= $c->req->param('cat_word_id');
	my $word	     	      	= $c->req->param('word');
	my $category_id	     	      	= $c->req->param('cat');

	$c->flash->{word} 		= $word;
	$c->flash->{word_id} 		= $word_id;
	$c->flash->{category_id} 	= $category_id;
	my ($definition) 		= $self->_get_def_array( {cat_word_id => $category_word_id, word_id => $word_id, category_id => $category_id} );
	
	$c->stash->{word_id}		= $c->flash->{word_id};
	$c->stash->{word}		= $c->flash->{word};	
	$c->stash->{category_id}	= $c->flash->{category_id};
	$c->stash->{definition}		= $definition;
	
}

#getRoles: Returns JSON object of the users roles to gridForm.js.  Used to control users access
sub getRoles: Local{
	my ( $self, $c )              = @_;

	my @roleList=();
        my $role_ref;

        if($c->user_exists){
              my $sql = "SELECT hg_user_roles.role_id, role FROM hg_user_roles, hg_roles  where user_id=" . $c->user->get('user_id') . " AND hg_user_roles.role_id = hg_roles.role_id;";
              $role_ref = SQLExec($sql, '\@@');
        }
        else{
             $c->res->redirect($c->uri_for($c->controller('Auth')->action_for('login')));
        }

	foreach my $chunk (@$role_ref){
        	my ($role_id, $role,) = @$chunk;
		
		push(@roleList, {role_id => $role_id, role => $role});
	}

    	$c->stash->{'json_data'} = \@roleList;
    	$c->detach($c->view('JSON'));
}

#TinyMCE javascrtpt rich text editor
sub editor : Local {
	my ($self, $c) = @_;
	my $term;
	my $w_id	     	      = $c->req->param('id');
	my $cat_id	     	      = $c->req->param('cat');
	my ($word, $word_id, $category_id, $definition) = $self->_get_def( {word_id => $w_id, category_id => $cat_id} );

	my $sql = "SELECT editable FROM hg_categories WHERE category_id = '$category_id';";
	my ($editable) = SQLExec($sql, '@');
	
	$c->stash->{action_url}       	= $c->config->{rootURL} . 'contentmgt/insert_text';
	$c->stash->{definition}       	= $definition;
	$c->stash->{readonly}	= 'false';
	$c->stash->{term}	      	= $word;
	$c->stash->{definition}	= $definition;
}

#_get_def: Pulls definition from database and returns it to definiton controller
sub _get_def_array : Private {
	my ( $self, $arg_ref )	      = @_;
	my $word_id 		      = $arg_ref->{'word_id'};
	my $category_id 	      = $arg_ref->{'category_id'};

	my %definition;
        my @def_array;

	my $sql ="SELECT a.category_word_id from hg_category_words a INNER JOIN hg_words b ON a.word_id=b.word_id WHERE b.word_id=$word_id AND a.category_id=$category_id";	
        	my($category_word_id) = SQLExec($sql, '@');
		warn "SQL CATEGORY_WORD_ID: $sql =--> $category_word_id";
		
	$sql = "SELECT definition_field_id, field_label FROM hg_definition_fields WHERE category_id=$category_id ORDER BY definition_field_id";
	my $data_ref = SQLExec($sql, '\@@');

	foreach my $chunk (@$data_ref){
        	my ($label_id,$label) = @$chunk;
		$sql = "SELECT b.data FROM hg_definition_data b INNER JOIN hg_category_words_has_definition_data a ON b.definition_data_id=a.definition_data_id WHERE a.category_word_id=$category_word_id AND b.definition_field_id=$label_id";
        	my($data) = SQLExec($sql, '@');
                $data =~ s/\\\"/\"/g;
                $data = WWW::HyperGlossary::Base->_html_unescape( $data );
                
                #decode the string from database
                $data = decode("utf8",$data);
		
		push(@def_array,{$label => $data}); 
	}

	return \@def_array;
}

#_get_def: Pulls definition from database and returns it to definiton controller
sub _get_def : Private {
	my ( $self, $arg_ref )	      = @_;
	my $category_word_id 	      = $arg_ref->{'cat_word_id'};
	my $word 		      = $arg_ref->{'word'};
        my $category_id               = $arg_ref->{'category_id'};
	my $definition;

	my $sql = "SELECT definition_field_id, field_label FROM hg_definition_fields WHERE category_id=$category_id ORDER BY definition_field_id";
	my $data_ref = SQLExec($sql, '\@@');

	foreach my $chunk (@$data_ref){
        	my ($label_id,$label) = @$chunk;
		$sql = "SELECT b.data FROM hg_definition_data b INNER JOIN hg_category_words_has_definition_data a ON b.definition_data_id=a.definition_data_id WHERE a.category_word_id=$category_word_id AND b.definition_field_id=$label_id";
                warn "RECORD : $sql";
        	my($data) = SQLExec($sql, '@');
                #$data = demoroniser($data);
                $data = WWW::HyperGlossary::Base->_html_unescape( $data );
                
                #decode the string from database
                $data = decode("utf8",$data);
		
		$definition .= "<br><b>". $label . ":</b><br>" . $data; 
	}

	return $definition;
}

#defData: Builds definition data JSON object 
sub defData : Local {
	my ( $self, $c )	      = @_;
	my $word_id	     	      = $c->req->param('word_id');
	my $category_id	     	      = $c->req->param('category_id');

	my $definition;
	my @dataList=();
	my $sql ="SELECT a.category_word_id from hg_category_words a INNER JOIN hg_words b ON a.word_id=b.word_id WHERE b.word_id=$word_id AND a.category_id=$category_id";	
        	my($category_word_id) = SQLExec($sql, '@');

	$sql = "SELECT definition_field_id, field_label, field_type_id, required, editable FROM hg_definition_fields WHERE category_id=$category_id";
	my $data_ref = SQLExec($sql, '\@@');

	foreach my $chunk (@$data_ref){
        	my ($label_id,$label,$field_type_id,$required,$editable) = @$chunk;
		$sql = "SELECT b.definition_data_id, b.data FROM hg_definition_data b INNER JOIN hg_category_words_has_definition_data a ON b.definition_data_id=a.definition_data_id WHERE a.category_word_id=$category_word_id AND b.definition_field_id=$label_id";
        	
                my($data_id, $data) = SQLExec($sql, '@');
                $data = WWW::HyperGlossary::Base->_html_unescape( $data );
                
                #decode the string from database
                my $X = decode("utf8",$data);
		push(@dataList, {field_label_id=>$label_id,field_label=>$label,field_type_id=>$field_type_id,definition_data_id=>$data_id,definition=>$X,required=>$required,editable=>$editable});
	}

    	$c->stash->{'json_data'} = \@dataList;
    	$c->detach($c->view('JSON'));
}

#getLanguage: returns JSON object of the languages in the database
sub getLanguage : Local {
	my ($self, $c) = @_;

	my $sql  =  "select language_id, language FROM hg_languages;";
	my ($languages) = SQLExec( $sql, '\@@' );
	
	my @langList=();
	foreach my $language ( @$languages ) {
		my ( $lang_id, $lang) = @$language;
		push(@langList, {id=>$lang_id,language=>$lang});
	}
	
    	$c->stash->{'json_lang'} = \@langList;
    	$c->detach($c->view('JSON'));
}

#getWordType: returns JSON object of the word type
sub getWordType : Local {
	my ($self, $c) = @_;

	my $sql  =  "select word_type_id, word_type FROM hg_languages;";
	my ($languages) = SQLExec( $sql, '\@@' );
	
	my @langList=();
	foreach my $language ( @$languages ) {
		my ( $lang_id, $lang) = @$language;
		push(@langList, {id=>$lang_id,language=>$lang});
	}
	
    	$c->stash->{'json_lang'} = \@langList;
    	$c->detach($c->view('JSON'));
}

#getFieldType:  returns JSON object of the available field types
sub getFieldType : Local {
	my ($self, $c) = @_;

	my $sql  =  "SELECT definition_type_id, definition_type FROM hg_definition_types;";
	my ($fieldTypes) = SQLExec( $sql, '\@@' );
	
	my @fieldList=();
	foreach my $type ( @$fieldTypes ) {
		my ( $ft_id, $ft) = @$type;
		push(@fieldList, {field_type_id=>$ft_id,field_type=>$ft});
	}
	
    	$c->stash->{'json_fields'} = \@fieldList;
    	$c->detach($c->view('JSON'));
}

#getDefFields: returns JSON object of the definition fields
sub getDefFields : Local {
	my ($self, $c) = @_;

        my $params;
        my $category_id = $c->request->param('category_id');

        my $sql = "SELECT definition_field_id, field_label, field_type_id, required, editable FROM hg_definition_fields WHERE category_id=$category_id ORDER BY definition_field_id";

        my $fields_ref = SQLExec($sql, '\@@');
	
	my @fieldsList=();
	foreach my $fieldInfo ( @$fields_ref ) {
		my ( $field_label_id, $field_label, $field_type_id, $required, $editable) = @$fieldInfo;
                my $editable_text;
                if($editable == 1){$editable_text = 'false';}else{$editable_text = 'true';}
                warn "$field_label\n";
		push(@fieldsList, {field_label_id=> $field_label_id, field_label=>$field_label, field_type_id=>$field_type_id, required=>$required, editable=>$editable_text});
	}

    	$c->stash->{'json_fields'} = \@fieldsList;
    	$c->detach($c->view('JSON'));
	
}

#getWordTypes: returns JSON object of the word types
sub getWordTypes : Local {
	my ($self, $c) = @_;

	my $sql  =  "SELECT * FROM hg_word_types;";
	my ($wordTypes) = SQLExec( $sql, '\@@' );
	
	my @fieldList=();
	foreach my $type ( @$wordTypes ) {
		my ( $wt_id, $wordtype) = @$type;
		push(@fieldList, {word_type_id=>$wt_id,word_type=>$wordtype});
	}
	
    	$c->stash->{'json_fields'} = \@fieldList;
    	$c->detach($c->view('JSON'));
}


#getIdentifierTypes: returns JSON object of the identifier types
sub getIdentifierTypes : Local {
	my ($self, $c) = @_;

	my $sql  =  "SELECT word_type_identifier_id, word_type_identifier FROM hg_word_type_identifiers;";
	my ($wordTypeIdents) = SQLExec( $sql, '\@@' );
	
	my @fieldList=();
	foreach my $type ( @$wordTypeIdents ) {
		my ( $wti_id, $wti) = @$type;
		push(@fieldList, {word_type_identifier_id=>$wti_id,word_type_identifier=>$wti});
	}
	
    	$c->stash->{'json_fields'} = \@fieldList;
    	$c->detach($c->view('JSON'));
}


#getIdentifiers: returns JSON object of the identifiers for a particular word type ie)Chemical - InChI
sub getIdentifiers : Local {
	my ($self, $c) = @_;

	my $sql  =  "SELECT hg_word_identifiers.word_identifier_id, hg_word_identifiers.identifier, hg_word_type_identifiers.word_type_identifier FROM hg_word_identifiers, hg_word_type_identifiers ";
           $sql .=  "WHERE category_word_id = " . $c->request->param('category_word_id') . " AND hg_word_identifiers.word_type_identifier_id = hg_word_type_identifiers.word_type_identifier_id" ;
           warn "GET_IDENTIFIEES: $sql";
	my ($wordIdents) = SQLExec( $sql, '\@@' );
	
	my @fieldList=();
	foreach my $idents ( @$wordIdents ) {
		my ( $wi_id, $identifier, $wti) = @$idents;
		push(@fieldList, {word_identifier_id=>$wi_id,identifier=>$identifier,word_type_identifier=>$wti});
	}
	
    	$c->stash->{'json_fields'} = \@fieldList;
    	$c->detach($c->view('JSON'));
}


#returns JSON object of the glossaries in the database
sub getCitation : Local {
	my ($self, $c) = @_;

	my $category_id	     	      	= $c->req->param('category_id');

	my $sql  =  "SELECT category_citation_id, citation, image_icon, bgcolor, fgcolor ";
           $sql .= "FROM hg_category_citations WHERE category_id = $category_id;";
	my ($citation_id,$citation,$image_icon,$bgcolor, $fgcolor) = SQLExec( $sql, '@' );
        $citation = WWW::HyperGlossary::Base->_html_unescape( $citation );
        $citation = decode("utf8",$citation);
	
	my @citationList = ({ citation_id  =>$citation_id,
                             citation      =>$citation,
                             image_icon    =>$image_icon,
                             bgcolor       =>$bgcolor,
                             fgcolor       =>$fgcolor
                            });
	
    	$c->stash->{'json_citation'} = \@citationList;
    	$c->detach($c->view('JSON'));
}

#addTerm: Add new term to a glossary
sub addTerm : Local {
	my ($self, $c) = @_;
        my($set_id) =1;	

        my $params                = {
			  	      language_id		=> $c->request->param('language'), 
			  	      category_id	 	=> $c->request->param('category_id'), 
			  	      term		 	=> $c->request->param('term'),
			  	      word_type_id		=> $c->request->param('word_type_id') 
				     };

        my $sql = "SELECT definition_field_id, field_label FROM hg_definition_fields WHERE category_id='$params->{category_id}'";
        my $fields_ref = SQLExec($sql, '\@@');

        $params->{term} = WWW::HyperGlossary::Base->_html_escape( $params->{term} ); 
        ################INSERT IN hg_word####################################
                $sql  = "SELECT word_id, word FROM hg_words WHERE word = '$params->{term}'";
                my ($word_id, $word) = SQLExec($sql,'@');
                if($word eq ''){
                        #####
                        $sql = "INSERT INTO hg_words (language_id, word) VALUES ('$params->{language}', '$params->{term}')";
                        SQLExec($sql);
                        warn "INSERT WORD: $sql\n";
            
                        $sql = "SELECT LAST_INSERT_ID()";
                        ($word_id) = SQLExec($sql, '@');

                }

                $sql = "INSERT INTO hg_category_words (category_id,set_id,word_id,word_type_id) VALUES ($params->{category_id},$set_id,$word_id,$params->{word_type_id})";
                SQLExec($sql);
                warn "INSERT CATEGORY_WORDS: $sql\n";
                my($category_word_id) = SQLExec('SELECT LAST_INSERT_ID()', '@');

        foreach my $field (@$fields_ref){
                
                my($definition_field_id, $field_label) = @$field;

                my $data = $c->request->param($field_label);
                $data= WWW::HyperGlossary::Base->_html_to_sql( $data );
           #####
            $sql  = "INSERT INTO hg_definition_data ( definition_field_id, data, user_id, creation_date)";
            $sql .= "VALUES ($definition_field_id, '$data', '" . $c->user->get('user_id')."', CURRENT_TIMESTAMP)";
            SQLExec($sql);
            warn "INSERT DEFINITION_DATA:  $sql\n";
            
            $sql = "SELECT LAST_INSERT_ID()";
            my ($definition_data_id) = SQLExec($sql, '@');
           #####
            $sql  = "INSERT INTO hg_category_words_has_definition_data (category_word_id, definition_data_id)";
            $sql .= "VALUES ($category_word_id, $definition_data_id)";
            SQLExec($sql);
            warn "INSERT CATEGORY_WORDS_HAS_DEFINITION_DATA: $sql\n";
           ##### 
        }

        $sql = "SELECT word_type_identifier_id, word_type_identifier FROM hg_word_type_identifiers WHERE word_type_id = $params->{word_type_id}";
        my $identifier_ref = SQLExec($sql, '\@@');

        foreach my $identifier (@$identifier_ref){
                my($word_type_identifier_id, $word_type_identifier) = @$identifier;

                my $data = $c->request->param($word_type_identifier);
                $data= WWW::HyperGlossary::Base->_html_to_sql( $data );
                $sql = "INSERT INTO hg_word_identifiers (identifier, word_type_identifier_id, category_word_id) VALUES ('$data', $word_type_identifier_id, $category_word_id)";
                SQLExec($sql);
        }
	#TODO need to add a check to make sure changes have been made
	
	$c->stash->{'success'}='true';

}

#deleteTerm: Delete a term from the glossary
sub deleteTerm : Local {
	my ($self, $c) = @_;
        my($set_id) =1;	

        my $params                = {
			  	      category_id	 	=> $c->request->param('category_id'), 
			  	      category_word_id		=> $c->request->param('cat_word_id'), 
			  	      word_id		        => $c->request->param('word_id'),
			  	      word_type_id		=> $c->request->param('word_type_id') 
				     };
        my $category_word_id = $params->{'category_word_id'};

        my $sql = "SELECT definition_data_id FROM hg_category_words_has_definition_data WHERE category_word_id = $category_word_id";
        my $definition_data_ref = SQLExec($sql,'\@@');
        
        foreach my $definition_data (@$definition_data_ref){
                
                my($definition_data_id) = @$definition_data;

                $sql = "DELETE FROM hg_definition_data WHERE definition_data_id = $definition_data_id";
                SQLExec($sql);
                warn "DELETE FROM HG_DEFINTION_DATA: $sql";
                $sql = "DELETE FROM hg_category_words_has_definition_data WHERE definition_data_id = $definition_data_id";
                SQLExec($sql);
                warn "DELETE FROM CONNECTION TABLE: $sql";
        }
                $sql = "DELETE FROM hg_category_words WHERE category_word_id = $category_word_id";
                SQLExec($sql);
                warn "DELETE FROM HG_CATEGORY_WORDS: $sql";

                $sql = "DELETE FROM hg_word_identifiers WHERE category_word_id = $category_word_id";
                SQLExec($sql);
                warn "DELETE FROM HG_WORD_IDENTIFIERS $sql";

        $sql = "SELECT word_id FROM hg_category_words WHERE word_id = '$params->{'word_id'}'";
        my ($word_id) = SQLExec($sql,'@');
        
        if(!$word_id){
                $sql = "DELETE FROM hg_words WHERE word_id = $params->{'word_id'}";
                SQLExec($sql);
                warn "DELETE FROM HG_WORDS: $sql";
        }

	$c->stash->{'success'}='true';
}

#deleteGlossary: Delete an entire  glossary
sub deleteGlossary : Local {
	my ($self, $c) = @_;


	my $category_id  = $c->request->param('category_id'); 


        my $sql = "SELECT definition_field_id FROM hg_definition_fields WHERE category_id='$category_id'";
        my $fields_ref = SQLExec($sql, '\@@');

        foreach my $field (@$fields_ref){
                
                my($definition_field_id) = @$field;
                $sql = "SELECT definition_data_id FROM hg_definition_data WHERE definition_field_id = '$definition_field_id'";
                my $definition_data_ids_ref = SQLExec($sql, '\@@');

                foreach my $rows (@$definition_data_ids_ref){
                        my ($definition_data_id) = @$rows;
                #      print "$definition_data_id\n";
                        $sql = "DELETE FROM hg_data_has_history_data WHERE definition_data_id = '$definition_data_id'";
                        SQLExec($sql);
                }

                
                $sql = "DELETE FROM hg_definition_data WHERE definition_field_id = $definition_field_id";
                SQLExec($sql);
                warn "DELETE FROM HG_DEFINTION_DATA: $sql";

                $sql = "DELETE FROM hg_definition_data_history WHERE definition_field_id = $definition_field_id";
                SQLExec($sql);
                warn "DELETE FROM HG_DEFINTION_DATA_HISTORY: $sql";
         }

        $sql = "SELECT word_id, category_word_id FROM hg_category_words WHERE category_id = '$category_id' ";
        my ($category_word_ref) = SQLExec($sql,'\@@');
        
        foreach my $category_word (@$category_word_ref){

                my($word_id, $category_word_id) = @$category_word;
                
                $sql = "DELETE FROM hg_word_identifiers WHERE category_word_id = $category_word_id";
                SQLExec($sql);
                warn "DELETE FROM HG_WORD_IDENTIFIERS $sql";
                
                $sql = "DELETE FROM hg_category_words_has_definition_data WHERE category_word_id = $category_word_id";
                SQLExec($sql);
                warn "DELETE FROM CONNECTION TABLE: $sql";
                
                #$sql = "DELETE FROM hg_category_words WHERE category_word_id = $category_word_id";
                #SQLExec($sql);
                #warn "DELETE FROM HG_CATEGORY_WORDS: $sql";
        
                $sql = "SELECT word_id FROM hg_category_words WHERE word_id = '$word_id'";
                my ($other_word_id) = SQLExec($sql,'@');
                
                if($other_word_id eq ''){
                        $sql = "DELETE FROM hg_words WHERE word_id = '$word_id'";
                        SQLExec($sql);
                        warn "DELETE FROM HG_WORDS: $sql";
                }
         }

         $sql = "DELETE FROM hg_definition_fields WHERE category_id = $category_id";
         SQLExec($sql);
         warn "DELETE FROM HG_DEFINITION_FIELDS: $sql";
         
         $sql = "DELETE FROM hg_category_citations WHERE category_id = '$category_id'";
         SQLExec($sql);
         $sql = "DELETE FROM hg_category_words WHERE category_id = '$category_id'";
         SQLExec($sql);

         
         $sql = "DELETE FROM hg_categories WHERE category_id = $category_id";
         SQLExec($sql);
         warn "DELETE FROM HG_CATEGORIES: $sql";

	$c->stash->{'success'}='true';
}

#toggleActice: Used to set or unset a glossary as active.  Un active glossary can only be seen by system admin
sub toggleActive : Local {
	 my ($self, $c) = @_;
	
	 my $category_id = $c->request->param('category_id');
        
         my $sql  = "SELECT active FROM hg_categories WHERE category_id = $category_id ";
         my ($active) = SQLExec($sql,'@');

         my $toggle;
         if($active == 0){ $toggle = 1;}
         if($active == 1){ $toggle = 0;}
         
         $sql  = "UPDATE hg_categories SET active = '$toggle' ";
         $sql .= "WHERE category_id = $category_id";
         warn "TOGGLE is $active: $sql\n";
         SQLExec($sql);
	
        
        $c->stash->{'success'}='true';

}

#updateTerm: Update a term in a glossary
sub updateTerm : Local {
	my ($self, $c) = @_;
	
	my $params                = {
			  	      language		 	=> $c->request->param('language'), 
			  	      word_id		 	=> $c->request->param('word_id'), 
			  	      word_type_id		=> $c->request->param('word_type_id'), 
			  	      word      		=> $c->request->param('word'), 
			  	      category_id	 	=> $c->request->param('category_id'), 
			  	      category_word_id	 	=> $c->request->param('category_word_id') 
				     };

#warn Dumper($params) . "<==========================\n";
        foreach ('word_id', 'category_id','language','word','category_word_id','word_type_id') { $params->{$_} = WWW::HyperGlossary::Base->_html_escape( $params->{$_} ); }
        my @definition_data_id = $c->req->param('definition_data_id');
        my $category_word_id = $c->req->param('category_word_id');

        ################UPDATE IN hg_word####################################
                my $sql = "SELECT hg_words.word FROM hg_words INNER JOIN hg_category_words ON hg_words.word_id=hg_category_words.word_id where hg_category_words.category_id='$params->{category_id}' AND hg_category_words.word_id='$params->{word_id}' LIMIT 0, 1";
                my ($original_word) = SQLExec($sql,'@');

                if($original_word ne $params->{word}){

                        $sql = "SELECT count(*) FROM hg_category_words WHERE word_id = '$params->{word_id}'";
                        my ($word_count) = SQLExec($sql,'@');

                        my $sql = "SELECT count(*) FROM hg_words WHERE word = '$params->{word}'";
                        my ($word_exists) = SQLExec($sql,'@');
                       #####
                       
                        #Word does not already exist and the current term is used by another glossary so need to create a new term
                        if($word_exists == 0 && $word_count > 1){
                                $sql = "INSERT INTO hg_words (language_id, word) VALUES ('$params->{language}', '$params->{word}')";
                                SQLExec($sql);
                                warn "INSERT WORD: $sql\n";
            
                                $sql = "SELECT LAST_INSERT_ID()";
                                my ($word_id) = SQLExec($sql, '@');

                                $sql = "UPDATE hg_category_words SET word_id = $word_id WHERE category_word_id = $params->{category_word_id}";
                                SQLExec($sql);

                                #$sql = "UPDATE hg_category_words_has_definition_data SET word_id = $word_id WHERE category_word_id = $params->{category_word_id}";
                                #SQLExec($sql);
                        }
                        #New word does not already exist and no other glossary is using this word so just change the term
                        if($word_exists == 0 && $word_count == 1){
                                my $sql = "UPDATE hg_words SET word = '$params->{word}' WHERE word_id = '$params->{word_id}'";
                                warn "IN UPDATE------------------\n";
                                SQLExec($sql);
                        }
                        #Word Exists so just update the category_word_id to word_id link
                        if($word_exists == 1){
                                my $sql = "SELECT word_id FROM hg_words WHERE word = '$params->{word}'";
                                my ($word_id) = SQLExec($sql,'@');
                                $sql = "UPDATE hg_category_words SET word_id = $word_id WHERE category_word_id = $params->{category_word_id}";
                                SQLExec($sql);
                       }

#
        }

	#TODO need to add a check to make sure changes have been made
        $sql = "SELECT definition_field_id, field_label, editable  FROM hg_definition_fields WHERE category_id='$params->{category_id}'";
        my $fields_ref = SQLExec($sql, '\@@');
        my $i=0;
        foreach my $field (@$fields_ref){
                
             my($definition_field_id, $field_label, $editable) = @$field;
             
             if($c->request->param($field_label) eq ''){$i++; next;}
             
             #skip if this field is not editable
             if($editable == 0){$i++; next;};

             my $data = $c->request->param($field_label);
             $data= WWW::HyperGlossary::Base->_html_to_sql( $data);
            
            if(($definition_data_id[$i] ne '') && ($definition_data_id[$i] ne 0)){
                  $definition_data_id[$i]= WWW::HyperGlossary::Base->_html_to_sql( $definition_data_id[$i] );

                  #INSERT old data into history table
                  my $sql  = "INSERT INTO hg_definition_data_history (definition_data_id, definition_field_id, user_id, data, creation_date) ";
                  $sql .= "SELECT definition_data_id, definition_field_id, user_id, data, creation_date FROM hg_definition_data WHERE ";
                  $sql .= "definition_data_id = $definition_data_id[$i]";
                  SQLExec($sql);
                  #warn "INSERT in HISTORY #$i: $sql";
            
                  $sql = "SELECT LAST_INSERT_ID()";
                  my ($history_data_id) = SQLExec($sql, '@');

                  #INSERT into data history connection table 
                  $sql = "INSERT INTO hg_data_has_history_data (definition_data_id, definition_data_history_id) VALUES ($definition_data_id[$i], $history_data_id)";
                  SQLExec($sql);
            
                  #Update the data for each field
                  $sql  = "UPDATE hg_definition_data SET data='$data', user_id='" . $c->user->get('user_id') . "', creation_date=CURRENT_TIMESTAMP ";
                  $sql .= "WHERE definition_data_id = $definition_data_id[$i]";
                  #warn "UPDATE #$i: $sql";
                  SQLExec($sql);
            }
            else{
           #####
            $sql  = "INSERT INTO hg_definition_data ( definition_field_id, data, user_id, creation_date)";
            $sql .= "VALUES ($definition_field_id, '$data', '" . $c->user->get('user_id')."', CURRENT_TIMESTAMP)";
            SQLExec($sql);
            #warn "INSERT DEFINITION_DATA:  $sql\n";
            
            $sql = "SELECT LAST_INSERT_ID()";
            my ($definition_data_id) = SQLExec($sql, '@');
           #####
            $sql  = "INSERT INTO hg_category_words_has_definition_data (category_word_id, definition_data_id)";
            $sql .= "VALUES ($category_word_id, $definition_data_id)";
            SQLExec($sql);
            #warn "INSERT CATEGORY_WORDS_HAS_DEFINITION_DATA: $sql\n";
           ##### 
            }

                  $i++;

        }
        $sql = "UPDATE hg_category_words SET word_type_id = $params->{word_type_id} WHERE category_word_id =" .$c->request->param('category_word_id');
        SQLExec($sql);

        $sql = "SELECT word_type_identifier_id, word_type_identifier FROM hg_word_type_identifiers WHERE word_type_id = $params->{word_type_id}";
        my $identifier_ref = SQLExec($sql, '\@@');

        $sql = "SELECT * FROM hg_word_identifiers WHERE category_word_id=". $c->request->param('category_word_id') . " LIMIT 0,1";
        my ($checkExist) = SQLExec($sql, '@');
        
        if($checkExist eq ''){
          foreach my $identifier (@$identifier_ref){
                  my($word_type_identifier_id, $word_type_identifier) = @$identifier;
                  my $data = $c->request->param($word_type_identifier);
                  
                  $data= WWW::HyperGlossary::Base->_html_to_sql( $data );
                  $sql = "INSERT INTO hg_word_identifiers (identifier, word_type_identifier_id, category_word_id) ";
                  $sql .= "VALUES ('$data','$word_type_identifier_id','".$c->request->param('category_word_id')."')";
                  #warn "INSERT IDENT: ----> $sql";
                  SQLExec($sql);
          }
        }
        else{
          foreach my $identifier (@$identifier_ref){
                  my($word_type_identifier_id, $word_type_identifier) = @$identifier;
  
                  my $data = $c->request->param($word_type_identifier);
                  $data= WWW::HyperGlossary::Base->_html_to_sql( $data );
                  $sql = "UPDATE hg_word_identifiers SET identifier='$data', word_type_identifier_id='$word_type_identifier_id' WHERE category_word_id = " . $c->request->param('category_word_id');
                  #warn "UPDATE IDENT: ----> $sql";
                  SQLExec($sql);
          }
        }
	$c->stash->{'success'}='true';

}

#dumpGloss: Dump the entire content of a glossary
sub dumpGloss : Local {
	my ($self, $c) = @_;

	my $params                = {
			  	      category		 	=> $c->request->param('category'), 
			  	      category_id	 	=> $c->request->param('category_id') 
				     };

        my $sql  =  "SELECT hg_category_words.category_word_id, hg_words.word_id, hg_words.word  FROM hg_words INNER JOIN hg_category_words ON ";
	$sql .=  "hg_words.word_id=hg_category_words.word_id where category_id='$params->{category_id}'";
        warn "GET WORDS: $sql";
	my ($words_ref) = SQLExec( $sql, '\@@' );
        
        my $dump = "<h1>$params->{category}</h1>\n";
        my $index=0; 
        foreach my $field (@$words_ref){
             $index++;   
             my ($category_word_id, $word_id, $word) = @$field;
             $dump .= "<h2>$index - $word </h2> <h5>(ID: $category_word_id)</h5>\n";
	
             my ($history) 	    = $self->_get_hist_def( {cat_word_id => $category_word_id, word_id => $word_id, category_id => $params->{category_id}} );
             
             $dump .= $history;

        }
	$c->stash->{'success'}='true';
        $c->stash->{'dump'} = $dump;
}        


#_get_hist_def: Get definition history
sub _get_hist_def : Private {
	my ( $self, $arg_ref )	      = @_;
	my $category_word_id 	      = $arg_ref->{'cat_word_id'};
	my $word 		      = $arg_ref->{'word'};
	my $category_id 	      = $arg_ref->{'category_id'};

	my $history;

	my $sql = "SELECT definition_field_id, field_label FROM hg_definition_fields WHERE category_id=$category_id";
	my $field_ref = SQLExec($sql, '\@@');

	foreach my $field (@$field_ref){
        	my ($field_id, $field_label) = @$field;
		
                $sql = "SELECT b.data, b.definition_data_id, b.user_id, b.creation_date  FROM hg_definition_data b INNER JOIN hg_category_words_has_definition_data a ON b.definition_data_id=a.definition_data_id WHERE a.category_word_id=$category_word_id AND b.definition_field_id=$field_id";
                warn "GET CURRENT DATA: $sql";
        	my($current_data, $definition_data_id, $current_user, $current_date) = SQLExec($sql, '@');
                $current_data = WWW::HyperGlossary::Base->_html_unescape( $current_data );
		
		$history .= "<br><b> $field_label last updated $current_date by user $current_user:</b><br>";
                if($current_data){$history .= $current_data;}else{$history .= "<p style='color:red'>NO DATA</p>";} 

                $sql = "SELECT b.data, b.creation_date, user_id FROM hg_definition_data_history b INNER JOIN hg_data_has_history_data a ON b.definition_data_history_id=a.definition_data_history_id WHERE a.definition_data_id=$definition_data_id AND b.definition_field_id=$field_id";
                warn "GET HISTORY DATA: $sql";
                my $data_ref = SQLExec($sql, '\@@');

                if(@$data_ref){$history .= "<h2> History for $field_label</h2>\n";}

                foreach my $chunk (@$data_ref){
                        my ($data, $date, $user) = @$chunk;
                        $data = WWW::HyperGlossary::Base->_html_unescape( $data );
		
                        $history .= "<br><b> <h3>Edited on $date by user with ID: $user </h3></b><br>\n";
                        if($data ne ''){$history .= "<p>$data</p>\n";}else{$history.="<p style='color: red'>NO DATA</p>\n";}
                        $history .= "<hr COLOR='blue' NOSHADE>\n";
                }
                        $history .= "<hr COLOR='green' NOSHADE>\n";
        }

	return $history;
}

#saveGloss: Save a new glossary
sub saveGloss : Local {
	my ($self, $c) = @_;
	
	my $params                = { glossname    	 	=> $c->request->param('glossname'),
			  	      editable		 	=> $c->request->param('editable'), 
			  	      fieldLabel		=> $c->request->param('fieldLabel'), 
			  	      fieldtype		 	=> $c->request->param('field_type'), 
			  	      required		 	=> $c->request->param('required'), 
			  	      citation		 	=> $c->request->param('citation'), 
			  	      image_icon		=> $c->request->param('image_icon'), 
			  	      fgcolor		 	=> $c->request->param('fgcolor'), 
			  	      bgcolor		 	=> $c->request->param('bgcolor') 
				     };
                                     
         foreach ('glossname', 'editable', 'citation') { $params->{$_} = WWW::HyperGlossary::Base->_html_to_sql( $params->{$_} ); }
         foreach ('glossname', 'editable', 'citation') { $params->{$_} = WWW::HyperGlossary::Base->_html_escape( $params->{$_} ); }
         $params->{citation}    = encode("utf8",$params->{citation});
         
         my @fieldLabel = $c->req->param('fieldLabel');
         my @fieldtype  = $c->req->param('field_type');
         my @required   = $c->req->param('required');
         my @editable   = $c->req->param('editable');
         
         my $sql  = "INSERT INTO hg_categories (category, user_id, editable, created) ";
            $sql .= "VALUES ( '$params->{glossname}', '" . $c->user->get('user_id')."', '1', CURRENT_TIMESTAMP);";
         warn "CATEGORY insert $sql ";
        SQLExec($sql);
            
         $sql = "SELECT LAST_INSERT_ID()";
         my ($category_id) = SQLExec($sql, '@');

        if($params->{citation}){
            $sql  = "INSERT INTO hg_category_citation (category_id, citation,image_icon,bgcolor,fgcolor) ";
            $sql .= "VALUES ($category_id, '$params->{citation}', '$params->{image_icon}', '$params->{bgcolor}', '$params->{fgcolor}')";
            SQLExec($sql);
        }

         my $i;
         my $size = scalar @fieldLabel;
         for($i = 0; $i<$size; $i++){
             foreach ($fieldLabel[$i], $fieldtype[$i], $editable[$i]) { $_ = WWW::HyperGlossary::Base->_html_escape( $_ ); }
             my $editable_binary;
             if($editable[$1] eq 'true'){ $editable_binary = 0; }else{$editable_binary = 1;}
             $sql  = "INSERT INTO hg_definition_fields ";
             $sql .= "(category_id, field_label, field_type_id, required, editable) ";
             $sql .= "VALUES ($category_id, '$fieldLabel[$i]', '$fieldtype[$i]', '$required[$i]', '$editable_binary')";
       
            SQLExec($sql);
           warn "DEFINITION_FIELDS: $sql\n";
         }

	#TODO need to add a check to make sure changes have been made
	
	$c->stash->{'success'}='true';
        $c->detach('View::JSON');
}

#updateGloss: Update an existing glossary
sub updateGloss : Local {
	my ($self, $c) = @_;
	
	  my $glossname    	 	= $c->request->param('glossname');
			  	      my $citation		 	= $c->request->param('citation'); 
			  	      my $fgcolor		 	= $c->request->param('fgcolor'); 
			  	      my $editable		 	= $c->request->param('editable'); 
			  	       my $bgcolor		 	= $c->request->param('bgcolor');
			  	       my $image_icon		 	= $c->request->param('image_icon');
                                     
         $citation    = encode("utf8",$citation);
         foreach ($glossname, $editable, $citation, $fgcolor, $bgcolor) { $_ = WWW::HyperGlossary::Base->_html_escape( $_ ); }
         foreach ($glossname, $editable, $citation, $fgcolor, $bgcolor) { $_ = WWW::HyperGlossary::Base->_html_to_sql( $_ ); }
         
         my @fieldLabel                 = $c->req->param('fieldLabel');
         my @definition_field_id        = $c->req->param('field_label_id');
         my @fieldtype                  = $c->req->param('field_type');
         my @required                   = $c->req->param('required');
         my @editable                   = $c->req->param('editable');
         my $category_id                = $c->req->param('category_id');

         my $sql  = "UPDATE hg_categories SET category = '$glossname', editable = '1' ";
            $sql .= "WHERE category_id = $category_id";
         warn "CATEGORY update $sql ";
         SQLExec($sql);
            
         $sql = "SELECT category_citation_id FROM hg_category_citations WHERE category_id = $category_id";
         my ($category_citation_id) = SQLExec($sql, '@');


         if($category_citation_id){
                $sql  = "UPDATE hg_category_citations SET citation = '$citation', ";
                $sql .= "bgcolor = '$bgcolor', fgcolor = '$fgcolor' WHERE category_id = $category_id";
                warn "CATEGORY update citation: $sql ";
                SQLExec($sql);
         }
         else{
                $sql  = "INSERT INTO hg_category_citations (category_id, citation,image_icon,bgcolor,fgcolor) ";
                $sql .= "VALUES ($category_id, '$citation', '$image_icon', '$bgcolor', '$fgcolor')";
                SQLExec($sql);
         }

	 my @fields_left;
         $sql = "SELECT definition_field_id FROM hg_definition_fields WHERE category_id = $category_id ORDER BY definition_field_id ASC";
         my $field_ids_ref = SQLExec($sql, '\@@');

         foreach my $ids (@$field_ids_ref){ my ($id) = @$ids; push(@fields_left, $id);}
        
        ##########################################
         my $i = 0;
         ##############################################

         foreach my $whatever (@definition_field_id){
        #	my ($field_id, $field_label) = @$field;
                foreach ($fieldLabel[$i], $fieldtype[$i], $editable[$i]) { $_ = WWW::HyperGlossary::Base->_html_escape( $_ ); }
                my $editable_binary;
                if($editable[$i] eq 'true'){ $editable_binary = 0; }else{$editable_binary = 1;}
             
                if($definition_field_id[$i] eq ''){
                        $sql  = "INSERT INTO hg_definition_fields ";
                        $sql .= "(category_id, field_label, field_type_id, required, editable) ";
                        $sql .= "VALUES ($category_id, '$fieldLabel[$i]', '$fieldtype[$i]', '$required[$i]', '$editable_binary')";
       
                        SQLExec($sql);
                        warn "DEFINITION_FIELDS INSERT: $sql\n";
                        my $index = 0;
                        foreach (@fields_left){
                                if($definition_field_id[$i] eq $_){splice(@fields_left, $index, 1); last;}
                                $index++;
                        }
                }
                elsif($definition_field_id[$i] ne ''){
                        $sql  = "UPDATE hg_definition_fields SET ";
                        $sql .= "field_label = '$fieldLabel[$i]', field_type_id = '$fieldtype[$i]', required = '$required[$i]', editable = '$editable_binary' ";
                        $sql .= "WHERE category_id = $category_id AND definition_field_id = $definition_field_id[$i]";
                        SQLExec($sql);
                        warn "DEFINITION_FIELDS UPDATE: $sql\n";
                        my $index = 0;
                        foreach (@fields_left){
                                if($definition_field_id[$i] eq $_){splice(@fields_left, $index, 1); last;}
                                $index++;
                        }
                }
                $i++;
         }
        
        foreach my $field_id_to_delete (@fields_left){
                #Delete before adding or updating fields
                $sql = "DELETE FROM hg_definition_fields WHERE category_id = $category_id AND definition_field_id = $field_id_to_delete";
                SQLExec($sql);
                warn "DEFINITION_FIELDS DELETE: $sql\n";
                $sql = "DELETE FROM hg_definition_data WHERE definition_field_id = $field_id_to_delete";
                SQLExec($sql);
        }
	#TODO need to add a check to make sure changes have been made
	
	$c->stash->{'success'}='true';
}

#fileUpload:  Upload the XML glossary document and bulk insert the terms and definitions
sub fileUpload : Local {
	my ( $self, $c )	      = @_;

        my $category_id = $c->req->param('category_id');
	my ($filename, $target);
 	
        if ( my $file = $c->request->upload('file') )
	{
		$filename = $file->filename;
		$target   = $c->config->{staticPATH} . "files/$filename";
		unless ( $file->link_to($target) || $file->copy_to($target) ) {
			die ( "Failed to copy '$filename' to '$target': $!" );
		}
	}

        my $handler = WWW::HyperGlossary::SAXchemeddlHandler->new;
        my $parser = XML::Parser::PerlSAX->new (Handler => $handler);

        my $glossary = $parser->parse(Source => {SystemId => $target});
        $self->_batchAddTerm({category_id =>$category_id, glossary => $glossary, user_id => $c->user->get('user_id')});
        
	$c->stash->{'success'}='true';
}

#Process uploaded XML content
sub _batchAddTerm {
	my ($self, $arg_ref) = @_;
        my($set_id) =1;	

        my $language_id = 25;
        my $category_id = $arg_ref->{'category_id'};
        my $glossary_ref = $arg_ref->{'glossary'};
        my $user_id = $arg_ref->{'user_id'};

        my $sql = "SELECT definition_field_id, field_label FROM hg_definition_fields WHERE category_id='$category_id' LIMIT 0,1";
        my ($definition_field_id, $field_label) = SQLExec($sql, '@');

        while (my ($term, $array) = each %$glossary_ref){
                my ($definition, $word_type, $word_type_identifier, $identifier) = @$array;
            #$term = WWW::HyperGlossary::Base->_html_escape( $term ); 
                $term       = WWW::HyperGlossary::Base->_html_to_sql($term);
                $term       = WWW::HyperGlossary::Base->_trim_white($term);
                $term       = encode("utf8",$term);
                $definition = WWW::HyperGlossary::Base->_html_to_sql($definition);
                $definition = encode("utf8",$definition);
                $identifier = WWW::HyperGlossary::Base->_html_to_sql($identifier);
                $identifier = encode("utf8",$identifier);

            #Get word_type_id if it exists
            $sql = "SELECT word_type_id FROM hg_word_types WHERE word_type = '$word_type'";
            my ($word_type_id) = SQLExec($sql, '@');
            
            #$definition= WWW::HyperGlossary::Base->_html_escape( $definition ); 
            warn "WORD ========> $term\n";
        ################INSERT IN hg_word####################################
                $sql  = "SELECT word_id, word FROM hg_words WHERE word = '$term'";
                my ($word_id, $word) = SQLExec($sql,'@');
                if($word eq ''){
                  warn "IN THE LOOPAROO 1!!!";
                        #####
                        $sql = "INSERT INTO hg_words (language_id, word) VALUES ('$language_id', '$term')";
                        SQLExec($sql);
                        warn "INSERT WORD: $sql\n";
            
                        $sql = "SELECT LAST_INSERT_ID()";
                        ($word_id) = SQLExec($sql, '@');

                }

                #check if this word already exits in this glossary. if so skip an go to next word
                $sql  = "SELECT category_word_id FROM hg_category_words WHERE word_id = '$word_id' AND category_id = '$category_id'";
                my ($category_word_id) = SQLExec($sql,'@');
                
                if($category_word_id eq ''){
                  warn "IN THE LOOPAROO 2!!!";
                      $sql = "INSERT INTO hg_category_words (category_id,set_id,word_id,word_type_id) VALUES ($category_id,$set_id,$word_id,$word_type_id)";
                      SQLExec($sql);
                      warn "INSERT CATEGORY_WORDS: $sql\n";
                      ($category_word_id) = SQLExec('SELECT LAST_INSERT_ID()', '@');
                }
               else{ next; };
            #####
              $sql  = "INSERT INTO hg_definition_data ( definition_field_id, data, user_id, creation_date)";
              $sql .= "VALUES ($definition_field_id, '$definition', '" . $user_id ."', CURRENT_TIMESTAMP)";
              SQLExec($sql);
              warn "INSERT DEFINITION_DATA:  $sql\n";
            
              $sql = "SELECT LAST_INSERT_ID()";
              my ($definition_data_id) = SQLExec($sql, '@');
            #####
            $sql  = "INSERT INTO hg_category_words_has_definition_data (category_word_id, definition_data_id)";
            $sql .= "VALUES ($category_word_id, $definition_data_id)";
            SQLExec($sql);
            warn "INSERT CATEGORY_WORDS_HAS_DEFINITION_DATA: $sql\n";
            #####

            #Insert identifier if one exists and type is known
            if($identifier && $word_type_id){
                $sql = "SELECT word_type_identifier_id FROM hg_word_type_identifiers WHERE word_type_identifier = '$word_type_identifier'";
                my ($word_type_identifier_id) = SQLExec($sql,'@');

                $sql = "INSERT INTO hg_word_identifiers (identifier, word_type_identifier_id, category_word_id)";
                $sql .= "VALUES ('$identifier', '$word_type_identifier_id', '$category_word_id')";
                SQLExec($sql);
            }

          #TODO need to add a check to make sure changes have been made
	
        }

        return;
}


#getMediaType:  returns JSON object of the available media types
sub getMediaType : Local {
	my ($self, $c) = @_;

	my $sql  =  "SELECT media_type_id, media_type FROM hg_media_types;";
	my ($mediaTypes) = SQLExec( $sql, '\@@' );
	
	my @fieldList=();
	foreach my $media_type ( @$mediaTypes ) {
		my ( $ft_id, $ft) = @$media_type;
		push(@fieldList, {media_type_id=>$ft_id, media_type=>$ft});
	}
	
    	$c->stash->{'json_fields'} = \@fieldList;
    	$c->detach($c->view('JSON'));
}

sub message : Local {
	my ($self, $c) = @_;
        my $message             = $c->req->param('message');
        
        $c->stash->{'message'} = $message;
}
#mediaUpload saves a video or image file either though fileupload or download
sub mediaUpload : Local {
	my ( $self, $c )	      = @_;

        my $url             = $c->req->param('url');
        my $source          = $c->req->param('source');
        my $description     = $c->req->param('description');
        my $keywords        = $c->req->param('keywords');
        my $media_type_id   = $c->req->param('media_type');
        my $media_name      = $c->req->param('medianame');
        my $category_id     = $c->req->param('category_id');
	

        my $sql = "SELECT media_type FROM hg_media_types WHERE media_type_id = $media_type_id";
        my ($media_type) = SQLExec($sql, '@');
        my $directory = $c->config->{staticPATH} . "files/$media_type".'s/'.$category_id.'/';
        my $local_url = $c->config->{rootURL} . "/static/files/$media_type".'s/'.$category_id.'/';
        
        #Check if directory exists 
        unless(-d $directory){
                mkdir $directory or die "create directory failed: $!";
        }

        #clean input
        foreach ($url, $source, $description, $keywords, $media_name) { $_ = WWW::HyperGlossary::Base->_html_to_sql( $_ ); }

        my ($filename, $target, $original_source, $original_media_file, $new_media_file);
 	
        if ($source eq 'fileupload'){
          if ( my $file = $c->request->upload('file') )
          {
                  $original_media_file = $file->filename;
                  my ($ext) = $original_media_file =~ /(\.[^.]+)$/;
                  $original_media_file =~ s/[^A-Za-z0-9\-\.]//g;
                  
                  #make unique string for filename
                  my $pass = new String::Random;
                  my $r_string = $pass->randpattern("ssssss");
                  $new_media_file = $category_id . "_" . $r_string. $ext;

                  $target   = $directory . $new_media_file;
                  unless ( $file->link_to($target) || $file->copy_to($target) ) {
                          die ( "Failed to copy '$new_media_file' to '$target': $!" );
                  }
                  $original_source = 'Personal Computer Upload:' . "($original_media_file)";
          }
        }
        if($source eq 'url'){
          $url =~ m/^.+[\\|\/](.+?)$/;
          $original_media_file    = $1;
          $original_media_file =~ s/[^A-Za-z0-9\-\.]//g;
          my ($ext) = $original_media_file =~ /(\.[^.]+)$/;
                  
                  #make unique string for filename
                  my $pass = new String::Random;
                  my $r_string = $pass->randpattern("ssssss");
                  $new_media_file = $category_id . "_" . $r_string . $ext;

          my $ua            = LWP::UserAgent->new();
          my $response      = $ua->get( $url );
          my $media_content = $response->content();
          
          my $filename = $directory . $new_media_file;
          open FILE, "> $filename" or die $!;
          print FILE $media_content;
          close FILE;
                  
          $original_source = $url;
        }
        
        $sql  = "INSERT INTO hg_media (media_name, description, keywords, url, original_source, category_id, user_id, media_type_id, upload_date) ";
        $sql .= "VALUES ('$media_name', '$description', '$keywords', '".$local_url . $new_media_file  ."', '$original_source', '$category_id', '". $c->user->get('user_id')."', '$media_type_id', CURRENT_TIMESTAMP)";
        SQLExec($sql);
        
        $self -> _build_java_file_list({static_path     => $c->config->{staticPATH},
                                        media_type_id   => $media_type_id, 
                                        media_type      => $media_type,
                                        category_id     => $category_id});

	$c->stash->{'success'}='true';
}

#Build the javascript files that supply the image list var for the tinymce editor.  A file is created for each glossary.
sub _build_java_file_list{
	my ($self, $arg_ref) = @_;

        my $java;
        my @java_array;

        my $filename = $arg_ref->{static_path} . "js/" . $arg_ref->{media_type} . "_list_$arg_ref->{category_id}.js";

        my $sql  =  "SELECT media_name, url FROM hg_media WHERE media_type_id = $arg_ref->{media_type_id} AND category_id = $arg_ref->{category_id}";
	my ($media_list) = SQLExec( $sql, '\@@' );
        
        if($arg_ref->{media_type} eq 'image'){$java = "var tinyMCEImageList = new Array(";}
        if($arg_ref->{media_type} eq 'video'){$java = "var tinyMCEMediaList = new Array(";}
	
	foreach my $media_type ( @$media_list ) {
		my ( $media_name, $url) = @$media_type;
                
                push(@java_array,'["' . $media_name . '" ,"' . $url . '"]'); 
	}
        $java .= join(',', @java_array);
        $java .= ');';
        
        open FILE, "> $filename" or die $!;
        print FILE $java;
        close FILE;
        
        return;
}

=head1 AUTHOR

root
0
This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
