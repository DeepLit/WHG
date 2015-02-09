package HyperGlossary;

use strict;
use warnings;

use Catalyst::Runtime 5.70;


# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use parent qw/Catalyst/;
use Catalyst qw/-Debug
                Unicode::Encoding
                ConfigLoader::Multi
                Static::Simple
		Authentication
		Authorization::Roles
		StackTrace
		Session
		Session::State::Cookie
		Session::Store::FastMmap/;
use Data::Dumper;
our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in hyperglossary.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.
__PACKAGE__->config->{static}->{ignore_extensions} = [
   qw/tmpl tt tt2 xhtml/
   ];

__PACKAGE__->config({ name => 'HyperGlossary',

 # 'AutoSession' => {
 #           prefix      => 'sess_',
 #           exclude     => [qw(logged_in_user logged_in_username)]
 #       },
 'View::JSON' => {
          encoding => 'UTF-8',
          allow_callback  => 1,    # defaults to 0
          callback_param  => 'cb', # defaults to 'callback'
          expose_stash    => qr/(^json_)|(^success$)/, # defaults to everything
        #  expose_stash    => [ qw( success ) ], # defaults to everything
      },
  'Plugin::Authentication'	=> {
  	default => {
		credential => {
			class 			=> 'Password',
			password_type		=> 'clear',
#			password_hash_type	=> 'SHA-256',
			password_field		=> 'user_pass'
		},
		store	=> {
			class 				=> 'DBIx::Class',
			user_model			=> 'hgDB::HgUsers',
			role_relation			=> 'roles',
			role_field			=> 'role',
			user_userdata_from_session	=> '1'
		}
	}
   },
  # 'Plugin::Session' => {
  #                      expires => 10000000000 #expires NEVER
  #             }


} );


# Load multiple YAML configuration files with Catalyst::Plugin::ConfigLoader::Multi 
__PACKAGE__->config( 'Plugin::ConfigLoader' => { file => __PACKAGE__->path_to('conf')  } );
__PACKAGE__->setup();


=head1 NAME

HyperGlossary - Catalyst based application

=head1 SYNOPSIS

    script/hyperglossary_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<HyperGlossary::Controller::Root>, L<Catalyst>

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
