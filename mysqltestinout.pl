#!/usr/bin/perl -w
use strict;
use GTFS;
use DBI;
use Stop;

my $gtfs_dir = "input/arlington_gtfs";
my $dbh = DBI->connect("DBI:CSV:f_dir=$gtfs_dir;f_ext=.txt;csv_sep_char=,;csv_quote_char=\"") or die "Could not connect: $DBI::errstr";

my $gtfs = GTFS->new($dbh);

my $username = "mperkins";
my $password = "secret";
my $database = "arlington_gtfs";

my $dbhout = DBI->connect("DBI:mysql:database=$database",$username,$password) or die "Could not connect: $DBI::errstr";

$gtfs->writeAlltoDB($dbhout);

#my $sth = $dbh->prepare("SELECT * FROM stop_times");
#$sth->execute;
#my $table_ary_ref = $sth->fetchall_arrayref({});


$dbh->disconnect;
$dbhout->disconnect;
