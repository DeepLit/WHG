package HyperGlossary::SchemaClass::HgWords;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hg_words");
__PACKAGE__->add_columns(
  "word_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "language_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "word",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 128 },
  "created",
  {
    data_type => "TIMESTAMP",
    default_value => "0000-00-00 00:00:00",
    is_nullable => 1,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("word_id");
__PACKAGE__->add_unique_constraint("word_ndx", ["word"]);


# Created by DBIx::Class::Schema::Loader v0.04002 @ 2010-01-27 09:28:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:n6iiL1D/jek2+l7fhdFVTg







# You can replace this text with custom content, and it will be preserved on regeneration
1;
