package HyperGlossary::SchemaClass::HgDefinitionData;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_definition_data");
__PACKAGE__->add_columns(
  "definition_data_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "definition_field_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "data",
  { data_type => "BLOB", default_value => "", is_nullable => 0, size => 65535 },
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "creation_date",
  {
    data_type => "TIMESTAMP",
    default_value => "0000-00-00 00:00:00",
    is_nullable => 1,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("definition_data_id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JZzu7IQlqRpk5Ckwfg59dQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
