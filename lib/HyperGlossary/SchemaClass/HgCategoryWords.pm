package HyperGlossary::SchemaClass::HgCategoryWords;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_category_words");
__PACKAGE__->add_columns(
  "category_word_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "category_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "set_id",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 2 },
  "word_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("category_word_id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Yy0Bjb8ZEHo+qn2oEbABaA







# You can replace this text with custom content, and it will be preserved on regeneration
1;
