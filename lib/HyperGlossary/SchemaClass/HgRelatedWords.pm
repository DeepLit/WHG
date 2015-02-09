package HyperGlossary::SchemaClass::HgRelatedWords;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_related_words");
__PACKAGE__->add_columns(
  "related_word_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "word_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "definition_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("related_word_id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:asNOGKynf6nLeaWZi2gacw







# You can replace this text with custom content, and it will be preserved on regeneration
1;
