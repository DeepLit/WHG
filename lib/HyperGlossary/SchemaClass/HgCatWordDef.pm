package HyperGlossary::SchemaClass::HgCatWordDef;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_cat_word_def");
__PACKAGE__->add_columns(
  "cwd_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "category_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "word_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "dd_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("cwd_id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0hQBE9lTjVmjW7G9uabs5Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
