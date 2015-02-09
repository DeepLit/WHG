package HyperGlossary::Controller::Hg;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use WWW::HyperGlossary::Model;
use WWW::HyperGlossary;
use DBI;
use DBIx::MySperql qw(DBConnect SQLExec SQLFetch $dbh);
use LWP::Simple;
#use Chemistry::OpenBabel;
use MIME::Base64::Perl;
use XML::Simple;
use URI;
use Encode;
use Data::Dumper;
use JSON::XS;
use HTML::TreeBuilder;

our ($category_id, $definition_type, $language_id, $mysperql_pdb, $hg_model);

=head1 NAME

HyperGlossary::Controller::Root - Root Controller for HyperGlossary

=head1 DESCRIPTION

Main Hyperglossary controller

=head1 METHODS

=cut

sub auto : Private {
	my ($self, $c)                 = @_;
	my $path                       = $c->request->path(); $path =~ s/\d+$//;
	   $c->stash->{template}       = $path . '.tt2';
	   $dbh                        = $c->controller('Root')->_connect( $c->config->{hgdb} );
           if($c->user_exists){
                  warn $c->model('hgDB::HgRoles') . $c->user->get('user_name') . " : " . $c->user->get('user_id');	   
           }
	if(exists $c->session->{category_id}){$c->stash->{category_id} = $c->session->{category_id}; warn "category_id is already set ".$c->session->{category_id};}else{ $c->session->{category_id} = 34;}
	if(exists $c->session->{language_id}){$c->stash->{language_id} = $c->session->{language_id};}else{ $c->session->{language_id} = 25;}
	if(exists $c->session->{category}){$c->stash->{category} = $c->session->{category};warn "YESYESYESYESYESYES";}else{ $c->session->{category} = 'General Chemistry';warn "NONONONONONONONONONO";}
        
        $mysperql_pdb = DBIx::MySperqlOO->new({ db=>'gene_pdb', user=>'root', pass=>'K16Tut' });
        $hg_model = WWW::HyperGlossary::Model->new();
}

#preferences:  Get the users preferences for a particular session form/controller
sub preferences : Local {
	my ( $self, $c )              = @_;
	$c->stash->{action_url}       = $c->config->{rootURL} . 'hg/save_preferences';

    	my $hg3                       = WWW::HyperGlossary->new();

	my $sql  =  "select category_id, category FROM hg_categories;";
	my ($categories) = SQLExec( $sql, '\@@' );
	$c->stash->{category_options}        = $hg3->_build_html_select_options( $categories, $c->stash->{category_id} );
	$c->stash->{definition_type_options} = $hg3->_build_html_select_options( $c->config->{hg_definition_types}, $c->stash->{definition_type_id} );
	$c->stash->{language_options}        = $hg3->_build_html_select_options( $c->config->{hg_languages}, $c->stash->{language_id} );
}

#url: URL input/form controller
sub url : Local {
	my ( $self, $c )              	= @_;
    	my $hg3                       	= WWW::HyperGlossary->new();
	$c->stash->{path}               = $c->request->path;
	$c->stash->{action_url}       	= $c->config->{rootURL} . 'hg/start_url';
	$c->stash->{exampleURL}	      	= 'http://www.science.uwaterloo.ca/~cchieh/cact/applychem/atmosphere.html';
	my $sql  =  "select category_id, category FROM hg_categories;";
	my ($categories) = SQLExec( $sql, '\@@' );
	$c->stash->{category_options}   = $hg3->_build_html_select_options( $categories, $c->session->{category_id} );
	$c->stash->{set_cat_url}       	= $c->config->{rootURL} . 'hg/save_preferences';
}

#text: Text input/form controller
sub text : Local {
	my ( $self, $c )                = @_;
	$c->stash->{action_url}         = $c->config->{rootURL} . 'hg/text_process';
	$c->stash->{path}               = $c->request->path;
    	my $hg3                         = WWW::HyperGlossary->new();
	$c->stash->{jsFiles}	 	= ['/static/js/tiny_mce/tiny_mce_src.js'];
	$c->stash->{readonly}	      	= 'false';
	my $sql  =  "select category_id, category FROM hg_categories;";
	my ($categories) = SQLExec( $sql, '\@@' );
	$c->stash->{category_options}   = $hg3->_build_html_select_options( $categories, $c->session->{category_id} );
	$c->stash->{set_cat_url}       	= $c->config->{rootURL} . 'hg/save_preferences';
}

#about: Displays the about information. Content in template
sub about : Local {
	my ( $self, $c )              = @_;
	$c->stash->{about}            = 'WikiHyperGlossary is a tool for chemical education.';

}

#text_process: Submit text to be processed
sub text_process : Local {
	my ( $self, $c )              = @_;
	my $plaintext  = $c->request->param('editor');
	
	# Get and parse text for first return
	my $hg    = WWW::HyperGlossary->new();
	my ($head,$body,$page_id)  = $hg->start_text({ text         => $plaintext, 
	                                               category_id  => $c->session->{category_id} }); 
	$c->session->{page_id} 		= $page_id;
	$c->session->{flag} 		= 1;
	$c->stash->{head} 		= $head;
	$c->stash->{jsFiles}	 	= ['/static/js/hg3.js','/static/js/jas.js'];
	$c->stash->{page_id} 		= $page_id;
	$c->stash->{body} 		= $body;
	$c->stash->{urlpage} 		= 1;
	$c->stash->{controller_url} = $c->config->{rootURL}.'hg/next_set';


}

#save_preferences:  Save the users preferences for a particular session
sub  save_preferences : Local {
	my ( $self, $c )              = @_;
	$c->stash->{template} = '';

	$c->session->{category_id}  			= $c->request->param('category');
	$c->session->{definition_type}     		= $c->request->param('definition_type');
	$c->session->{language_id}	            	= $c->request->param('language');
	
	my $sql  =  "SELECT category FROM hg_categories WHERE category_id=" . $c->session->{category_id}; 
	($c->session->{category}) = SQLExec( $sql, '@' );
        
        $c->response->status(204);
        $c->response->body("\n\n");
}

#start_url: Submit URL to get processed
sub start_url : Local {
	my ( $self, $c ) = @_;
	$c->session->{url}              = $c->request->param('url');
	my $category_id  		= $c->flash->{category_id};

warn "START_CITY: ".$c->session->{url};
	# Get and parse html for first return
	my $hg    = WWW::HyperGlossary->new();
	my ($head,$body,$page_id)  = $hg->start_url({ url         => $c->session->{url}, 
	                             		      category_id => $c->session->{category_id} }); 
	$c->session->{page_id} = $page_id;
	$c->session->{flag} = 1;

	$c->stash->{jsFiles}	 	= ['static/js/hg3.js','static/js/jas.js'];
	$c->stash->{head} 		= $head;
	$c->stash->{page_id} 		= $page_id;
	$c->stash->{body} 		= $body;
	$c->stash->{urlpage} 		= 1;
	$c->stash->{controller_url} = $c->config->{rootURL}.'hg/next_set';
}

#next_set: Return the page as each word set is processed
sub next_set : LocalRegex('next_set(\d+)$') {
	my ($self, $c) = @_;
	my $page_id    = $c->req->captures->[0];
	my $text;
	
        # Process the next set
	my $hg   = WWW::HyperGlossary->new();
	
	if($c->session->{flag} == 2){
		$text = $hg->get_cached_page({ page_id => $page_id });
	}
	else{
		$c->session->{flag}++;
		$text = $hg->next_set({ page_id => $page_id, hg_words => $c->config->{hg_words}, current_set => $c->session->{flag} });
	}

	# Return special page
	$c->stash->{template} = '';
    	$c->response->body( $text );
}

#export_page: Build the a page that has been processed to exported and used independent of the local server
sub export_page : Local {
	my ( $self, $c ) = @_;
        
        my $export;

        my $page_id = $c->session->{page_id}; 
        my $sql  = "SELECT url, body FROM hg_pages WHERE page_id = '$page_id'";
        my ( $url,$body ) = SQLExec( $sql, '@' );
	
        #Build the head an direct link to javascript on server
        $export .= "<head>\n";
        $export .= '<link rel="icon" type="image/png" href="'.$c->config->{rootURL}.'static/images/HG.png" />'."\n";
        $export .= '<link rel="stylesheet" type="text/css" href="'.$c->config->{rootURL}.'static/js/ext/resources/css/ext-all.css" />'."\n";
        $export .= '<link rel="stylesheet" type="text/css" href="'.$c->config->{rootURL}.'static/js/ext/resources/css/xtheme-gray.css" />'."\n";
        $export .= '<link rel="stylesheet" type="text/css" href="'.$c->config->{rootURL}.'static/js/livegrid/build/resources/css/ext-ux-livegrid.css" />'."\n";
        $export .= '<link rel="stylesheet" type="text/css" href="'.$c->config->{rootURL}.'static/js/ext/resources/css/fileuploadfield.css" />'."\n";
        
        $export .= '<script type="text/javascript"> var base_url = "'.$c->config->{rootURL}.'";</script>'."\n";
                                  
        $export .= '<script type="text/javascript" src="'.$c->config->{rootURL}.'static/js/ext/adapter/ext/ext-base.js"></script>'."\n";
        $export .= '<script type="text/javascript" src="'.$c->config->{rootURL}.'static/js/ext/ext-all.js"></script>'."\n";
        $export .= '<script type="text/javascript" src="'.$c->config->{rootURL}.'static/js/ext/Ext.ux.ColorField.js"></script>'."\n";
        $export .= '<script type="text/javascript" src="'.$c->config->{rootURL}.'static/js/ext/basex/ext-basex.js"></script>'."\n";
        $export .= '<script type="text/javascript" src="'.$c->config->{rootURL}.'static/js/ext/mif/uxvismode.js"></script>'."\n";

        $export .= '<script type="text/javascript" src="'.$c->config->{rootURL}.'static/js/ext/mif/multidom.js"></script>'."\n";
        $export .= '<script type="text/javascript" src="'.$c->config->{rootURL}.'static/js/ext/mif/mif.js"></script>'."\n";
        $export .= '<script type="text/javascript" src="'.$c->config->{rootURL}.'static/js/jmol/Jmol.js"></script>'."\n";
        $export .= '<script type="text/javascript" src="'.$c->config->{rootURL}.'static/js/ext/examples/ux/FileUploadField.js"></script>'."\n";
        $export .= '<script type="text/javascript" src="'.$c->config->{rootURL}.'static/js/jas.js"></script>'."\n";
        my $javascript = &export_javascript($c->config->{rootURL}, $c->session->{category_id});
        $export .= '<script type="text/javascript">'.$javascript.'</script>'."\n";

        $export .= "<base href='$url'></base>"."\n";
        $export .= "</head>\n";
        $export .= $body;

        my $filename = 'hg_page_export.html'; 
        # Return special page
	$c->stash->{template} = '';
        $c->response->header('Content-Disposition',qq[attachment; filename="$filename"]);
    	$c->response->body( $export );
}

#getCount:  Get the count of the number of words in a glossary
sub getCount : Local {

	my ($self, $c) = @_;
	
	my $category_id 	= $c->session->{category_id};
        
        my $sql  = "SELECT COUNT(*) FROM hg_category_words ";
           $sql .= "WHERE category_id = '$category_id'";
	my ($count) = SQLExec( $sql, '@' );
    	
	$c->response->body( $count );
}

#chemEdArticle: Get chenEddl articles
sub chemEdArticle : Local{
	my ( $self, $c )              = @_;
	my $term	     	      = $c->req->param('name');

	$c->stash->{nowrap}	      = 1;
	$c->stash->{term}             = $term;
	my $rootURL 		      = 'http://www.chemeddl.org:8080/';
	my $service 		      = 'alfresco/service/custom/articles/search/';
	my $query 		      = '?year=2000&month=october&author=&audience=&domain=&element=&topic=&pedagogy=&text='.$term;
	my $auth     		      = $self->_get_chemEd_auth();
	

	my $articles   		      = get($rootURL . $service . $query . $auth);
	$articles    		      =~ m/<body(.*?)>(.*)<\/body>/six;
	$articles		      =~ s/href="\//href="http:\/\/chemeddl.org:8080\//g;
	$c->stash->{articles}	      = $articles;
}

sub searchChemEdDL : Local {
	my ( $self, $c )              = @_;
	my $term	     	      = $c->req->param('term');
        my $content = get('http://www.chemeddl.org/resources/models360/files/searchlist.php?q='.$term);
  
        return 
}

#jmol: Get jmol and display applet (now set to use Jsmol)
sub jmol : Local{
	my ( $self, $c )              = @_;
	my $term	     	      = $c->req->param('term');
	my $category_id;
        $c->stash->{template} = 'hg/jsmol.tt2';
	if($c->req->param('category_id')){$category_id = $c->req->param('category_id');}else{ $category_id = $c->session->{category_id};}
        my $smile;
        my $url;
        my $inchi_key;
	
	my $sql = "SELECT word_id FROM hg_words WHERE word='$term'";
	my($word_id) = SQLExec($sql, '@');
	
        $sql = "SELECT category_word_id, word_type_id FROM hg_category_words WHERE word_id = $word_id AND category_id = $category_id";
	my($category_word_id, $word_type_id) = SQLExec($sql, '@');
        
        if($word_type_id == 2){
                      
              $sql  = "SELECT identifier FROM hg_word_identifiers WHERE category_word_id = $category_word_id ";
              $sql .= "AND word_type_identifier_id = 1";
              my($inchi) = SQLExec($sql, '@');
              
              warn "INCHI^^^^^^^ $inchi\n";
              $inchi_key = $self->_inchiToOther({inchi => $inchi, operation => 'InChIToInChIKey'});

              #my $content = get('http://144.92.39.69/resources/models360/modelsJmol.php?inchikey='.$inchi_key);
              #$url = 'http://144.92.39.69/resources/models360/modelsJmol.php?inchikey='.$inchi_key;
              my $content = get('http://www.chemeddl.org/resources/models360/modelsJmol.php?inchikey='.$inchi_key);
              $url = 'http://www.chemeddl.org/resources/models360/modelsJmol.php?inchikey='.$inchi_key;
             
             warn "URL: $content";
             my $base = '<base href="http://www.chemeddl.org/resources/models360/" />';
             #my $logo = '<a href="/"><img src="img/logoChemEdDL.gif" style="border: 0pt none;"></a><span id="headerText">Models 360</span>';
             
             #$content =~ s/\"\/(tools\/jmol)\"/\"http:\/\/144\.92\.39\.69\/$1\"/;
             #$content =~ s/(load)\s(files)/$1 http:\/\/144\.92\.39\.69\/resources\/models360\/$2/g;
             #my $info = 'Info0 = {'."\n";
                #$info .= 'use: "HTML5", '."\n"; 
                #$info .= 'width: 380, height: 380,'."\n"; 
                #$info .= 'color: "black",'."\n"; 
                #$info .= 'isSigned: false,'."\n"; 
                #$info .= 'jarFile: "JmolApplet0.jar",'."\n"; 
                #$info .= 'serverURL: "http://www.chemeddl.org/tools/jsmol/"'."\n"; 
                #$info .= 'serverURL: "http://hyperglossary.org/static/js/jsmol/php/jsmol.php",'."\n"; 
                #$info .= 'jarPath: "http://www.chemeddl.org/tools/jsmol/java",'."\n"; 
                #$info .= 'j2sPath: "http://www.chemeddl.org/tools/jsmol/j2s" };'."\n"; 
                #$info .= 'disableJ2SLoadMonitor: false,'."\n";
                #$info .= 'disableInitialConsole: true'."\n";
                #$info .= '}'."\n";
                #$info .= 'Jmol._alertNoBinary = false;'; 
             #$content =~ s/Info0.*?}/$info/ms;   
             #$content =~ s/\.\.\/\.\.\/(tools\/jsmol.*)/http:\/\/www\.chemeddl\.org\/$1/g;
             #$content =~ s/(files.*\.js)/http:\/\/www\.chemeddl\.org\/resources\/models360\/$1/g;
             #$content =~ s/(library.*\.[js|css])/http:\/\/www\.chemeddl\.org\/resources\/models360\/$1/g;
             #$content =~ s/(load)\s(files)/$1 http:\/\/www\.chemeddl\.org\/resources\/models360\/$2/g;
 #            warn "CONTENT: $content";
#             my $html = HTML::TreeBuilder->new;
#             my $root = $html->parse($content);
#             warn $1. "<====================---------";
#my $baselink = HTML::Element->new( 
#        'base', 
#        'href' => 'http://www.chemeddl.org/resources/models360/',
#        );

             #unshift(@{$root->find('head')->content_array_ref},$base);
             #$root->find('head')->insert_element($baselink);
             #unshift(@{$root->find('head')->content_array_ref},$logo);
             
             #$content = $root->as_HTML;
             my $error = 'gave no results'; 
             #my $error = 'load'; 
              if($content =~ /.*$error.*/){
                  $c->stash->{local} = 1;
                  my $filename = $term;
                  $filename=~s/[\W]//g;
                  $filename = $filename .'.mol2';
                  my $file = $c->config->{staticPATH}.'jmolFile/'.$filename;
                  warn "FILE 000000> $file\n";

                  unless(-e $file){
                          #$smile = $self->_openBabelWebService({what => $inchi, fromFormat => 'inchi', toFormat => 'smiles' });
                          $smile = $self->_inchiToOther({inchi=> $inchi, operation => 'InChIToSMILES'});
                          $self->_smileToMol2({smile => $smile, filename => $filename, staticPATH => $c->config->{staticPATH}});
                  }
                  $c->stash->{jmolFile}	        = $c->config->{rootURL} .'static/jmolFile/'.$filename;
                  $c->stash->{jsFiles}	 	= [$c->config->{rootURL} .'static/js/jmol/Jmol.js'];
              }
              else{
                #$c->stash->{chemeddl}	 	= 'http://www.chemeddl.org/resources/models360/models.php?inchikey='.$inchi_key;
                $c->stash->{chemeddl}	 	= 'http://chemdata.umr.umn.edu/acs_chemeddl/LAMP/resources/models360/models.php?inchikey='.$inchi_key;
                $c->stash->{SHIT}	 	= 1;
              }

        }

	$c->stash->{nowrap}	        = 1;

}

#jchempaint: Get 2D structure (SMILE structure)
sub jchempaint : Local{
	my ( $self, $c )              = @_;
	my $term	     	      = $c->req->param('term');
	#my $category_id 	      = $c->session->{category_id};
	my $category_id;
	if($c->req->param('category_id')){$category_id = $c->req->param('category_id');}else{ $category_id = $c->session->{category_id};}
        my $smile;

	my $sql = "SELECT word_id FROM hg_words WHERE word='$term'";
	my($word_id) = SQLExec($sql, '@');
	
        $sql = "SELECT category_word_id, word_type_id FROM hg_category_words WHERE word_id = $word_id AND category_id = $category_id";
	my($category_word_id, $word_type_id) = SQLExec($sql, '@');
        if($word_type_id == 2){
                $sql  = "SELECT identifier FROM hg_word_identifiers WHERE category_word_id = $category_word_id ";
                $sql .= "AND word_type_identifier_id = 1";
                my($inchi) = SQLExec($sql, '@');
        
                #$smile = $self->_inchiToSmile({inchi => $inchi});
                $smile = $self->_cactusConverter({fromFormat=> $inchi, toFormat => 'JME'});
                warn "$smile <---------------------------------";
        }
	$c->stash->{template}         = 'hg/jsme.tt2';
	$c->stash->{jme}	        = $smile;
	$c->stash->{nowrap}	        = 1;

}


#chemSpider: Get ChemSpider Content
sub chemSpider : Local{
	my ( $self, $c )              = @_;
	my $term	     	      = $c->req->param('term');
	#my $category_id 	      = $c->session->{category_id};
        my $inchi;
        my $spider_id_array;
	my $category_id;
	if($c->req->param('category_id')){$category_id = $c->req->param('category_id');}else{ $category_id = $c->session->{category_id};}

        my $token = 'f0cc0b75-342a-4e72-853a-9784c821d552';
        my $spider_thumbnail_service = 'http://www.chemspider.com/Search.asmx/GetCompoundThumbnail';
        

	my $sql = "SELECT word_id FROM hg_words WHERE word='$term'";
	my($word_id) = SQLExec($sql, '@');
	
        $sql = "SELECT category_word_id, word_type_id FROM hg_category_words WHERE word_id = $word_id AND category_id = $category_id";
        warn "GET WORD TYPE: $sql";
	my($category_word_id, $word_type_id) = SQLExec($sql, '@');
        
        if($word_type_id == 2){
              $spider_id_array = $self->_chemSpiderThumbnailSearch({term => $term, staticPath => $c->config->{staticPATH}});
        }
        $c->stash->{chemspider} = \@$spider_id_array;
        $c->stash->{word_type} = $word_type_id;
}

#Display proteins that have a pdb file
sub uniprotJmol : Local {
        my ($self, $c) = @_;

        my $word                      = $c->req->param('term');
        my $category_id               = $c->session->{category_id};

        my($word_id) = $hg_model->get_word_id({word => $word});
        my($category_word_id, $word_type_id) = $hg_model->get_category_word_id({word => $word, category_id => $category_id});
        my($word_identifier_id, $identifier) = $hg_model->get_word_identifier_id({category_word_id => $category_word_id});

        my $sql = "SELECT pdb_id FROM uniprot_to_pdb WHERE uniprotkb_id = '$identifier' LIMIT 0,1";
        my($pdb) = $mysperql_pdb->sqlexec($sql, '@');

        $c->stash->{jmolFile}           = $c->config->{rootURL} . 'pdb/'.$pdb.'.pdb.gz';
        $c->stash->{jsFiles}            = [$c->config->{rootURL} .'static/js/jmol/Jmol.js'];


        $c->stash->{nowrap}             = 1;

}


#chemSpider: Get ChemSpider Content
sub jChemPaintToChemSpider : Local{
	my ( $self, $c )              = @_;
	my $smiles	     	      = $c->req->param('smiles');
warn "SMILES: $smiles";
        $c->stash->{template} = 'hg/chemSpider.tt2';
        
        my $path = $c->config->{staticPATH};
        my $inchi_key;

       if($smiles){
        warn $smiles."<---------";
            my $inchi = $self->_smilesToInchi({smiles=> $smiles});
            $inchi_key = $self->_inchiToOther({inchi => $inchi, operation => 'InChIToInChIKey'});
        }

        my $spider_id_array = $self->_chemSpiderThumbnailSearch({term => $inchi_key, staticPath => $path});
        if(@$spider_id_array){
              $c->stash->{chemspider} = \@$spider_id_array;
        }
        else{$c->stash->{spider_message} = "No results found for the query using the smile string: \n $smiles";}
        $c->stash->{word_type} = 2;
}


sub _chemSpiderThumbnailSearch{
	my ( $self, $arg_refs)              = @_;

        my @spider_id_array;

        my $token = 'f0cc0b75-342a-4e72-853a-9784c821d552';
        my $spider_thumbnail_service = 'http://www.chemspider.com/Search.asmx/GetCompoundThumbnail';
        
        my $browser = LWP::UserAgent->new;
        
        my $xml = new XML::Simple;

        my $spider_simple_service = 'http://www.chemspider.com/Search.asmx/SimpleSearch';
                
                #Get thumbnail image of chemical word
                my $simple_url = URI->new( $spider_simple_service );
                $simple_url->query_form(
                        'query'         => $arg_refs->{term},
                        'token'         => $token,
                );
                my $spider_simple_content = $browser->get($simple_url);
                my $chemspider_simple_data = $xml->XMLin($spider_simple_content->content,ForceArray => 1);
                my $chemspider_ref = $chemspider_simple_data->{int};

                foreach my $chemspider_id (@$chemspider_ref){
                        
                        #Get thumbnail image of chemical word
                        my $thumbnail_url = URI->new( $spider_thumbnail_service );
                        $thumbnail_url->query_form(
                                'id'            => $chemspider_id,
                                'token'         => $token,
                        );


                        my $spider_thumbnail_content = $browser->get($thumbnail_url);
                
                        #Get XML thumbnail content and decode 64bit string 
                        my $data = $xml->XMLin($spider_thumbnail_content->content);
                        my $decoded_64 = decode_base64($data->{content});
                
                        open(FILE, '>' . $arg_refs->{staticPath} . 'files/' . $chemspider_id . '.png');
                        print FILE $decoded_64;
                        close(FILE);
		
                        push(@spider_id_array,$chemspider_id); 
              }
       return \@spider_id_array;
}


#chemEdMovie: Get ChemEdDL video
sub chemEdMovie : Local{
	my ( $self, $c )              = @_;
	my $term	     	      = $c->req->param('term');
	
	$c->stash->{jsFile}	 	= ['/static/js/QTP_Library.js','/static/js/AC_Quicktime.js'];
	my $rootURL 		      = 'http://www.chemeddl.org:8080/';
	my $service                   = 'alfresco/service/custom/video/';
	my $query                     = '?name='.$term;
	my $auth     		      = $self->_get_chemEd_auth();
	my $video                     = get($rootURL . $service . $query . $auth);
	$video                        =~ m/<body.*?>(.*)<\/body>/six;
	$video		              =~ s/\/alfresco/http:\/\/www.chemeddl.org:8080\/alfresco/g;

	$c->stash->{video}	    = $video;
}

#_get_chemEd_auth: Get authorization ticket from chemeddl
sub _get_chemEd_auth : Private{
	my ( $self)	      = @_;

	my $rootURL 	 	= 'http://www.chemeddl.org:8080/';
	my $ticketXML 		= get($rootURL . 'alfresco/service/api/login?u=mabauer&pw=chemeddl1MAB');
	$ticketXML 		=~ /<ticket>(.*)<\/ticket>/g;
	my $ticket 		= $1;
	my $auth 		= '&alf_ticket=' . $ticket;
	
	return $auth
}


#Build definiton page popup window
sub definition : Local{
	my ( $self, $c )              = @_;

	my $term	     	      = $c->req->param('term');
	my ($word_id, $category_id, $definition_type_id, $definition) = $self->_get_def( {term => $term} );
	
	$c->stash->{nowrap}	      = 1;
	$c->stash->{definition}       = $definition;
	$c->stash->{term}             = $term;
}

#defTran: Using google translate application to translate the definition
sub defTran : Local{
	my ( $self, $c )              = @_;

	my $word	     	      = $c->req->param('term');
	my $category_id 	      = $c->session->{category_id};

	my $sql = "SELECT word_id FROM hg_words WHERE word='$word'";
	my($word_id) = SQLExec($sql, '@');
	
        $sql = "SELECT citation,image_icon,bgcolor,fgcolor FROM hg_category_citations WHERE category_id = '$category_id'";
        my($citation,$image_icon,$bgcolor,$fgcolor) = SQLExec($sql, '@');

	my ($definition) 		= $self->_get_def( {word_id => $word_id, category_id => $category_id} );
	
	$c->stash->{template}         = 'hg/hg_definition.tt2';
	$c->stash->{nowrap}	      = 1;
	$c->stash->{definition}       = $definition;
	$c->stash->{term}             = $word;
	$c->stash->{citation}         = $citation;
	$c->stash->{iconImage}        = $image_icon;
	$c->stash->{bgcolor}          = $bgcolor;
	$c->stash->{fgcolor}          = $fgcolor;
}


#_get_def: Pulls definition from database and returns it to definiton controller
sub _get_def : Private {
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

#view_def: View defintion including older versions
sub view_def : Local {
	my ($self, $c) = @_;
	my $term;
	
        $c->req->param('word') ? ($term = $c->req->param('word')) : ($term = $c->flash->{term});
	
        my $definition_id = $c->req->param('def_id');
	my ($word_id, $category_id, $definition_type_id, $definition) = $self->_get_def( {term => $term, def_id => $definition_id} );

 	my $html = $self->_buildSelect( {term => $term} );

	$c->stash->{action_url}       		= $c->config->{rootURL} . 'hg/view_def';
	$c->stash->{definition}       		= $definition;
	$c->stash->{term}	      		= $term;
	$c->stash->{versionSelect}	      	= $html;

}


#_buildSelect: Dynamically build the select
sub _buildSelect
{
	my ($self, $argref)                 = @_;
        my ($html, $selected, $current_id);

	my $sql  =  "select definition_id, revision_date FROM hg_definitions, hg_words WHERE ";
	   $sql .=  "hg_words.word_id=hg_definitions.word_id AND word='$argref->{term}' ORDER BY revision_date DESC;";
	
	warn 'HTML SELELCT SQL: '.$sql;
	my ($definition_ids) = SQLExec( $sql, '\@@' );

	$html .= "<select name='def_id'>\n";
        if (! $current_id) { $current_id = 0; $html .= "        <option value=''> "; }

        foreach my $datum (@{ $definition_ids }) {
                my ($id, $label) = @$datum;
                if ($id == $current_id) { $selected = ' selected'; } else { $selected = ''; }
                $html .= "      <option value='$id' $selected> $label ";
        }

	$html .= "</select>\n";
        return $html;


}
#uses ChemSpiders open Babel Web Service to convert between different chemical identifiers
sub _openBabelWebService {
        my ($self, $arg_refs) = @_;

        my $spider_openbabel_service = 'http://www.chemspider.com/OpenBabel.asmx/Convert';

        my $browser = LWP::UserAgent->new;
        
        my $xml = new XML::Simple;
        
        my $simple_url = URI->new( $spider_openbabel_service );
        $simple_url->query_form(
                'what'          => $arg_refs->{what},
                'fromFormat'    => $arg_refs->{fromFormat},
                'toFormat'      => $arg_refs->{toFormat}
        );
        my $spider_simple_content = $browser->get($simple_url);
        my $to_format= $xml->XMLin($spider_simple_content->content);
        
        return $to_format->{content};
}

sub _cactusConverter {
        my ($self, $arg_refs) = @_;

        my $cactus_service = 'http://cactus.nci.nih.gov/chemical/structure/'.$arg_refs->{fromFormat}."/file";

        my $browser = LWP::UserAgent->new;
        
        
        my $simple_url = URI->new( $cactus_service );
        $simple_url->query_form(
                'format'      => $arg_refs->{toFormat}
        );
        my $cactus_content = $browser->get($simple_url);
        #my $to_format= $xml->XMLin($cactus_content->content);
        my $results = $cactus_content->content; 
        chomp($results);
        return $results;
}

sub _smilesToInchi {
        my ($self, $arg_refs) = @_;

        my $spider_smiles_service = 'http://www.chemspider.com/InChI.asmx/SMILESToInChI';

        my $browser = LWP::UserAgent->new;
        
        my $xml = new XML::Simple;
        
        my $simple_url = URI->new( $spider_smiles_service );
        $simple_url->query_form(
                'smiles'      => $arg_refs->{smiles}
        );
        my $spider_simple_content = $browser->get($simple_url);
        my $to_format= $xml->XMLin($spider_simple_content->content);
        
        return $to_format->{content};
}

sub _inchiToOther{
	my ($self, $arg_refs)                 = @_;

        my $token = 'f0cc0b75-342a-4e72-853a-9784c821d552';

        my $spider_inchi_to_key_service = 'http://www.chemspider.com/InChI.asmx/' . $arg_refs->{operation};
        
        my $browser = LWP::UserAgent->new;
        
        my $xml = new XML::Simple;
                
        #Get thumbnail image of chemical word
        my $simple_url = URI->new( $spider_inchi_to_key_service );
        $simple_url->query_form(
                'inchi'         => $arg_refs->{inchi},
        );

        my $spider_simple_content = $browser->get($simple_url);
        my $inchi_key = $xml->XMLin($spider_simple_content->content);
        
        return $inchi_key->{content};
}

#_smileToMol2: Converts a smile string to a Mol2 file using Ballon
sub _smileToMol2 {
	my ($self, $argref) = @_;
        my $smile = $argref->{smile};
        
        $smile =~s/\t//g;
        chomp($smile);
        $smile = "\"$smile\"";
        
        my $mmff_file = $argref->{staticPATH} . 'jmolFile/MMFF94.mff';
        my $out_file = $argref->{staticPATH} . 'jmolFile/'.$argref->{filename};
        #my $cmd = "balloon --nconfs 1 --noGA  $out_file";

        local $SIG{'CHLD'}='IGNORE';
        my $cmd = $argref->{staticPATH} . "jmolFile/balloon -f $mmff_file --nconfs 1 --noGA $smile $out_file";
        my $shit = system($cmd);

        return;
}
#hg_word_identifier: Using google translate application to translate the definition
sub hg_word_identifier : Local{
        my ( $self, $c )              = @_;

        my $word                      = $c->req->param('term');
        my $callback                  = $c->req->param('whgCallbackFunction');
        my $category_id               = $c->session->{category_id};
	if(exists $c->session->{category_id}){$category_id = $c->session->{category_id};}else{ $category_id = $c->req->param('category');}

         #get category_word_id
            my $sql = "SELECT category_word_id FROM hg_words, hg_category_words WHERE hg_category_words.word_id=hg_words.word_id AND ";
               $sql .= "hg_category_words.category_id = '$category_id' AND hg_words.word='$word'";
            my($category_word_id) = SQLExec( $sql, '@' );
warn $sql;
        #get word_identifier 
            #my $sql = "SELECT identifier_id FROM hg_word_identifiers WHERE category_word_id ='$arg_ref->{category_word_id}'";
               $sql = "SELECT hg_word_identifiers.word_identifier_id, hg_word_identifiers.identifier, hg_word_type_identifiers.word_type_identifier_id ";
               $sql .= "FROM hg_word_identifiers, hg_word_type_identifiers WHERE category_word_id = '$category_word_id' ";
               $sql .= "AND hg_word_identifiers.word_type_identifier_id = hg_word_type_identifiers.word_type_identifier_id";
            my($word_identifier_id, $identifier,$word_type_identifier_id) = SQLExec( $sql, '@' );

warn $sql;
        if(!$word_type_identifier_id){$word_type_identifier_id = 0;}
        if($callback){
                my $json = JSON::XS->new();
                my $jsonStructure->{word_identifier_type} = $word_type_identifier_id;
                my $json_cb = $json->encode({'json_data'=>[$jsonStructure]});
                $c->res->header('Content-Type', 'text/javascript');
                #my $whg_cb = 'function whgCallbackFunction(){var word_identifier_type='.$word_type_identifier_id.';alert("SHIT");}';

                my $whg_cb = $callback.'(('.$json_cb.'))';
                $c->response->body($whg_cb);
        }
        else{
                $c->stash->{'json_data'} = {word_identifier_type => [$word_type_identifier_id]};
                $c->detach($c->view('JSON'));
       }
}

sub export_javascript {
	my ($rootURL, $category) = @_;

        my $javascript = <<EOF;
  Ext.onReady(function() {
var category = $category;
function check_term_identifier(target){
    var conn = new Ext.data.Connection();
var identifier = Ext.data.Record.create([
        { name: 'word_identifier_type',  type: 'int' }
    ]);

var Store = new Ext.data.JsonStore({
        proxy: new Ext.data.ScriptTagProxy({
                        url            : '$rootURL/hg/hg_word_identifier',
                        callbackParam  : 'whgCallbackFunction',
                        callbackPrefix : 'WHG',
                        scriptIdPrefix : 'whgScript'
        }),
        baseParams: {"term": target.innerHTML, "category": category},
        root:       'json_data',
        fields:     identifier
    });

var word_identifier_type;
Store.load( {
                callback: function(){
                                Store.each(function(record){
                                identifier_type = record.data['word_identifier_type'];
                                hg_window_display(target,identifier_type);
                                });
                          }
          });

/*Store.on('load',function(){
alert("YEAH BOY!!");
                        identifier_type = Store.getAt(0);
                        alert(identifier_type);
                        hg_window_display(target,identifier_type);
});*/

/*
    conn.request({
          url: '$rootURL/hg/hg_word_identifier?term='+target.innerHTML+'&category='+category
         ,method: 'POST'
         ,params: {"term": target.innerHTML, "category": category}
         ,success: function(response,options) {
                        var data = Ext.decode(response.responseText);
                        identifier_type = data.json_data.word_identifier_type;
                        hg_window_display(target,identifier_type);
                }
         ,failure: function(f,a) {

                        Ext.Msg.alert('Status', 'No response from server');
                }
         ,listeners: {
                 'requestcomplete':{
                            fn: function(conn,res,opt){
                                  alert('DONESKI!!!!');
                                  },
                            scope: this
                            }
                 }
   });
*/
   Ext.Ajax.on("requestcmplete", function(conn,response,options){alert("DONE!!");});
  // return identifier_type;
}

    
Ext.select('.hg3').highlight("0000ff", { attr: 'color', duration: 5});

	Ext.QuickTips.init()
    Ext.select('body').on('click', function(e, t) {
        var t = Ext.get(t);
        if(t.hasClass('hg3')){
            var target = e.getTarget();

            identifier_type_id = check_term_identifier(target);
        }
  });//eo on('click'
}); // eo function onReady
  
function queryChemSpider(smiles) {
    var searchURL = '$rootURL/hg/jChemPaintToChemSpider';
    var spiderSearchPanel = new Ext.ux.ManagedIFrame.Panel({
                        autoLoad:{
                                  url      : searchURL
                                ,params         : {smiles :smiles}}
                ,title          : 'SMILE String Search'
                ,defaults       : {border:false, activeTab:0}
                ,hideMode       : 'nosize'
                ,constrain      : true
                ,closable       : true
    });
    
    tabP.add(spiderSearchPanel);

}


function hg_window_display(target,identifier_type){
var category_id = $category;
        var movieURL      = '$rootURL/hg/chemEdMovie?term='+target.innerHTML;
        var chemspiderURL = '$rootURL/hg/chemSpider?term='+target.innerHTML;
        var jchemURL      = '$rootURL/hg/jchempaint?term='+target.innerHTML+'&category_id='+category_id;
        var jmolURL       = '$rootURL/hg/jmol?term='+target.innerHTML;
        var defURL        = '$rootURL/hg/defTran?term='+target.innerHTML;
  
    var defpanel = ({
        	defaultSrc	: defURL
        	,title		: 'Definition'
                ,xtype          : 'iframepanel'
                ,layout         : 'fit'
    });
    
    var spiderpanel = new Ext.ux.ManagedIFrame.Panel({
        	defaultSrc	: chemspiderURL
        	,title		: 'ChemSpider Results'
                ,defaults	: {border:false, activeTab:0}
		,hideMode	: 'nosize'
		,constrain	: true
    });
    var moviepanel = new Ext.ux.ManagedIFrame.Panel({
        	defaultSrc	: movieURL
        	,title		: 'ChemEd DL Video'
                ,defaults	: {border:false, activeTab:0}
		,hideMode	: 'nosize'
		,constrain	: true
    });
    var jmolpanel = new Ext.ux.ManagedIFrame.Panel({
        	defaultSrc	: jmolURL
        	,title		: '3D Structure Model'
                ,defaults	: {border:false, activeTab:0}
		,hideMode	: 'nosize'
		,constrain	: true
    });

    var jchempaintpanel = new Ext.ux.ManagedIFrame.Panel({
        	defaultSrc	: jchemURL
        	,title		: '2D Structure Model'
                ,defaults	: {border:false, activeTab:0}
		,hideMode	: 'nosize'
		,constrain	: true
    });

    
    var tab_items = new Array();
    tab_items[0] = defpanel;
    if(identifier_type == 1){
                tab_items[1] = spiderpanel;
                tab_items[2] = jmolpanel;
                tab_items[3] = jchempaintpanel;
    }

    tabP = new Ext.TabPanel({
             title              : 'HyperGlossary'
            ,enableTabScroll    : true
            ,activeTab          : 0
            ,items              : tab_items
    });


            win = new Ext.Window({
                title           : 'Information Overlay For: '+target.innerHTML,
                layout          : 'fit',
                constrain       : true,
   		width           : 600,
   		height          : 500,
                closable        : true,
                border          : true,
		items           : [tabP]
            });
        

  win.show(this); 
}
EOF

        return $javascript; 
}

1;

