#!/usr/bin/perl -w
use strict;
use GTFS;
use DBI;

my $gtfs_dir = "input/arlington_gtfs";
my $dbh = DBI->connect("DBI:CSV:f_dir=$gtfs_dir;f_ext=.txt;csv_sep_char=,;csv_quote_char=\"") or die "Could not connect: $DBI::errstr";

my $gtfs = GTFS->new($dbh,{patterns => 0});

my $username = "mperkins";
my $password = "secret";
my $database = "arlington_gtfs";
my $dbhout = DBI->connect("DBI:mysql:database=$database",$username,$password) or die "Could not connect: $DBI::errstr";

#$gtfs->writeAlltoDB($dbhout);

$gtfs->transfertable("agency",$dbhout);
$gtfs->transfertable("stops",$dbhout);
$gtfs->transfertable("routes",$dbhout);
$gtfs->transfertable("trips",$dbhout);
$gtfs->transfertable("stop_times",$dbhout);
$gtfs->transfertable("calendar",$dbhout);
$gtfs->transfertable("calendar_dates",$dbhout);
$gtfs->transfertable("shapes",$dbhout);

$dbh->disconnect;
$dbhout->disconnect;
