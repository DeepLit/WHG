#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.

use FindBin;
BEGIN { do "$FindBin::Bin/script/env" or die $@ }

use inc::Module::Install;

name 'HyperGlossary';
all_from 'lib/HyperGlossary.pm';

requires 'local::lib' => '1.004002';
requires 'Catalyst::Runtime' => '5.80005';
requires 'Catalyst::Devel';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Plugin::Unicode::Encoding';
requires 'Catalyst::Plugin::ConfigLoader::Multi';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::FastMmap'; #Force install required
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::View::JSON';
requires 'Catalyst::View::TT';
requires 'Catalyst::Model::Factory';
requires 'parent';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
requires 'DBI';
requires 'DBIx::MySperql';
requires 'LWP::Simple';
#requires 'Chemistry::OpenBabel';
requires 'MIME::Base64::Perl';
requires 'XML::Simple';
requires 'URI';
requires 'Encode';
requires 'CGI::Browse';
requires 'Data::Dumper';
requires 'XML::Parser::PerlSAX';
requires 'Set::Infinite';
requires 'HTML::Encoding';
requires 'charnames';
requires 'Regexp::List'; #Force install required
requires 'DBIx::Class::Schema';
requires 'Mail::Builder::Simple';
requires 'Text::Demoroniser';
requires 'DateTime::Format::MySQL';
requires 'FCGI';
requires 'MooseX::NonMoose';
requires 'MooseX::MarkAsMethods';
requires 'YAML::XS';
requires 'String::Random';


catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
