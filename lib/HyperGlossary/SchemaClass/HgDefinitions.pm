package HyperGlossary::SchemaClass::HgDefinitions;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_definitions");
__PACKAGE__->add_columns(
  "definition_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "word_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "category_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "definition_type_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
  "definition",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "revision_date",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 1,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("definition_id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lzvospN/9tETUqJucwsGrw







# You can replace this text with custom content, and it will be preserved on regeneration
1;
