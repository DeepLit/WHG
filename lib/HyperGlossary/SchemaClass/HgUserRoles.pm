package HyperGlossary::SchemaClass::HgUserRoles;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_user_roles");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "role_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("user_id", "role_id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kxszHgNaWUsLl28lFbcpyQ





#__PACKAGE__->belongs_to(
#	role_id => 'HyperGlossary::SchemaClass::HgRoles'
#);

__PACKAGE__->belongs_to(
	"role","HyperGlossary::SchemaClass::HgRoles",{"foreign.role_id" => "self.role_id"}
);
__PACKAGE__->belongs_to(
	"user_id","'HyperGlossary::SchemaClass::HgUsers",{"foreign.user_id" => "self.user_id"}
);


#__PACKAGE__->belongs_to(
#	user_id => 'HyperGlossary::SchemaClass::HgUsers'
#);


#__PACKAGE__->many_to_many(roles=>'user_roles','role');
# You can replace this text with custom content, and it will be preserved on regeneration
1;
