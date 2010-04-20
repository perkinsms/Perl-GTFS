#!/usr/bin/perl -w
use strict;
use GTFS;
use DBI;
use Stop;

my $username = "anonymous";
my $password = "";
my $database = "wmata_gtfs";

my $dbh = DBI->connect("DBI:mysql:database=$database",$username,$password) or die "Could not connect: $DBI::errstr";

#my $gtfs_data = GTFS->new($dbh);
my $gtfs = GTFS->new($dbh);
my $stops = $gtfs->getStopsfromDB();

$dbh->disconnect;
