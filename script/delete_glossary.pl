#!/usr/bin/env perl

use FindBin;
BEGIN { do "$FindBin::Bin/env" or die $@ }

use DBIx::MySperql qw(DBConnect SQLExec SQLFetch $dbh);
use warnings;
use strict;

my $server   = 'localhost';
my $user     = 'root';
my $passwd   = 'K16Tut';
my $db       = 'hg_clean';

$dbh = DBConnect(database => $db, host => $server, user => $user, pass => $passwd);

my $category_id;
my $category;
my $category_id_check;

START:
do {

	my $sql = "SELECT category_id, category FROM hg_categories";
	my $categories_ref = SQLExec($sql, '\@@');

	print "ID:\t\t\tCategory \n";
	foreach my $rows (@$categories_ref){
        	($category_id, $category) = @$rows;
		print "$category_id:\t\t\t$category \n";
	}
	print "Enter Glossary id to delete: ";
	chomp(my $promt_category_id = <STDIN>);
	if($promt_category_id eq 'exit' || $promt_category_id eq 'quit'){exit}

	$sql = "SELECT category_id FROM hg_categories WHERE category_id = '$promt_category_id'";
	($category_id_check) = SQLExec($sql, '@');
	if(!$category_id_check){print "$category_id is not a valid category ID\n";}
	else {$category_id = $promt_category_id;}
}while (!$category_id_check);

print "Deleting!!!!\n\n";

	my $sql = "SELECT word_id, category_word_id FROM hg_category_words WHERE category_id = '$category_id'";
	my $category_word_ids_ref = SQLExec($sql, '\@@');
	
	my $count = 0;
	foreach my $rows (@$category_word_ids_ref){
        	#my ($category_word_id) = @$rows;
		#print "$category_word_id\n";
		++$count;
	}
print "Count: ". $count."\n";

foreach my $rows (@$category_word_ids_ref){
        my ($word_id, $category_word_id) = @$rows;
#print "$category_word_id\n";
        $sql = "DELETE FROM hg_category_words_has_definition_data WHERE category_word_id = '$category_word_id'";
        SQLExec($sql);
        $sql = "DELETE FROM hg_word_identifiers WHERE category_word_id = '$category_word_id'";
        SQLExec($sql);

	$sql = "SELECT word_id FROM hg_category_words WHERE word_id = '$word_id'";
        my ($other_word_id) = SQLExec($sql,'@');

        if($other_word_id eq ''){
                $sql = "DELETE FROM hg_words WHERE word_id = '$word_id'";
                SQLExec($sql);
                warn "DELETE FROM HG_WORDS: $sql";
        }


}

$sql = "SELECT definition_field_id FROM hg_definition_fields WHERE category_id = '$category_id'";
my $def_field_ids_ref = SQLExec($sql, '\@@');

foreach my $rows (@$def_field_ids_ref){
        my ($def_field_id) = @$rows;
        print "$def_field_id\n";
        $sql = "SELECT definition_data_id FROM hg_definition_data WHERE definition_field_id = '$def_field_id'";
        my $definition_data_ids_ref = SQLExec($sql, '\@@');

        foreach my $rows (@$definition_data_ids_ref){
        my ($definition_data_id) = @$rows;
          #      print "$definition_data_id\n";
                $sql = "DELETE FROM hg_data_has_history_data WHERE definition_data_id = '$definition_data_id'";
                SQLExec($sql);
        }

        $sql = "DELETE FROM hg_definition_data WHERE definition_field_id = '$def_field_id'";
        SQLExec($sql);
        $sql = "DELETE FROM hg_definition_data_history WHERE definition_field_id = '$def_field_id'";
        SQLExec($sql);


}


$sql = "DELETE FROM hg_category_citations WHERE category_id = '$category_id'";
SQLExec($sql);
$sql = "DELETE FROM hg_definition_fields WHERE category_id = '$category_id'";
SQLExec($sql);
$sql = "DELETE FROM hg_category_words WHERE category_id = '$category_id'";
SQLExec($sql);
$sql = "DELETE FROM hg_categories WHERE category_id = '$category_id'";
SQLExec($sql);

print "DONE DONE DONE DONE!\n";
goto START;
