package HyperGlossary::SchemaClass::HgRoles;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_roles");
__PACKAGE__->add_columns(
  "role_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "role",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 30 },
);
__PACKAGE__->set_primary_key("role_id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PwAyo2Rd+ueyN185GL8rKQ






#__PACKAGE__->many_to_many('roles','user_roles','role');
__PACKAGE__->has_many(
	hguser => 'HyperGlossary::SchemaClass::HgUserRoles', 'user_id'
);
__PACKAGE__->many_to_many(users =>'hgusers','user_id');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
