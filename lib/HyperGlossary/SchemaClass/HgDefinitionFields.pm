package HyperGlossary::SchemaClass::HgDefinitionFields;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_definition_fields");
__PACKAGE__->add_columns(
  "definition_field_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "category_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "field_label",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 40 },
  "field_type_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "required",
  { data_type => "INT", default_value => 1, is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("definition_field_id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hD8PAEeaMOpIMjrwK9ZYeg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
