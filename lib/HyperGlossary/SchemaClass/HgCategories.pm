package HyperGlossary::SchemaClass::HgCategories;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_categories");
__PACKAGE__->add_columns(
  "category_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "category",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 32 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "editable",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 1 },
  "created",
  {
    data_type => "TIMESTAMP",
    default_value => "0000-00-00 00:00:00",
    is_nullable => 1,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("category_id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pJM40y4Z7844Ro7Mg4F7Tw







# You can replace this text with custom content, and it will be preserved on regeneration
1;
