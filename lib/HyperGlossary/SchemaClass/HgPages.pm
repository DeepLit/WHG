package HyperGlossary::SchemaClass::HgPages;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_pages");
__PACKAGE__->add_columns(
  "page_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "category_id",
  { data_type => "INT", default_value => 1, is_nullable => 1, size => 10 },
  "url",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "html",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "body",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "set_id",
  { data_type => "INT", default_value => 1, is_nullable => 1, size => 1 },
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("page_id", "user_id");


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1azfRiq3QsjuXYRd9wifbQ







# You can replace this text with custom content, and it will be preserved on regeneration
1;
