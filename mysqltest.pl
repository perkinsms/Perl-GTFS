#!/usr/bin/perl -w
use strict;
use GTFS;
use DBI;

my $username = "mperkins";
my $password = "secret";
my $database = "wmata_gtfs";

my $dbh = DBI->connect("DBI:mysql:database=$database",$username,$password) or die "Could not connect: $DBI::errstr";

my $gtfs = GTFS->new($dbh,{create_patterns => 1, load_patterns=>1, loaddata=>1});

$gtfs->writePatternstoFile("input/$database/patterns.txt");

$dbh->disconnect;
