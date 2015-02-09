package HyperGlossary::SchemaClass::HgGroups;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_groups");
__PACKAGE__->add_columns(
  "hg_group_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "hg_group_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 45,
  },
);
__PACKAGE__->set_primary_key("hg_group_id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eqglOQt6M31kM4yxmWSIqg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
