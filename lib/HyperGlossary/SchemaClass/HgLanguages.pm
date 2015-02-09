package HyperGlossary::SchemaClass::HgLanguages;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_languages");
__PACKAGE__->add_columns(
  "language_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "language_code",
  { data_type => "CHAR", default_value => "", is_nullable => 0, size => 2 },
  "language",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("language_id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F7MkxmPkIcXO7bvQK8JdWQ







# You can replace this text with custom content, and it will be preserved on regeneration
1;
