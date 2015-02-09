package HyperGlossary::SchemaClass::HgDefinitionTypes;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_definition_types");
__PACKAGE__->add_columns(
  "definition_type_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "definition_type",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("definition_type_id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/g3t+IMhOoSd5axxoB6wTw







# You can replace this text with custom content, and it will be preserved on regeneration
1;
