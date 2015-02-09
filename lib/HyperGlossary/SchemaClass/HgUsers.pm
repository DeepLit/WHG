use utf8;
package HyperGlossary::SchemaClass::HgUsers;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HyperGlossary::Schema::Result::HgUser

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<hg_users>

=cut

__PACKAGE__->table("hg_users");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 first_name

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 last_name

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 60

=head2 user_name

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 user_pass

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 status

  data_type: 'varchar'
  default_value: 'active'
  is_nullable: 0
  size: 16

=head2 failed_login_1

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 last_success

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "first_name",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "last_name",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 60 },
  "user_name",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "user_pass",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "status",
  {
    data_type => "varchar",
    default_value => "active",
    is_nullable => 0,
    size => 16,
  },
  "failed_login_1",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "last_success",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "updated",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-01-24 05:26:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YQ36g/0d3xkUl6csxfZuLg
__PACKAGE__->has_many(
        user_roles => 'HyperGlossary::SchemaClass::HgUserRoles', 'user_id'
);

__PACKAGE__->many_to_many(roles => 'user_roles','role');

use Email::Valid;
sub new {
        my ($class, $args) = @_;

        if( exists $args->{email} && !Email::Valid->address($args->{email})){
                die 'Invalid Email Address';
        }

        return $class->next::method($args);
}

sub has_role {
        my ($self, $role) = @_;

        my $roles = $self->user_roles->find({role_id=>$role->role_id});

        return $roles;
}

sub set_all_roles {
        my ($self, @roleids) = @_;

        $self->user_roles->delete;

        foreach my $role_id (@roleids){
                $self->user_roles->create({ role_id => $role_id});
        }

        return $self;
}



# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
