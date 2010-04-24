#!/usr/bin/perl -w
use strict;
use GTFS;
use DBI;
use Stop;

my $username = "mperkins";
my $password = "secret";
my $database = "wmata_gtfs";

my $dbh = DBI->connect("DBI:mysql:database=$database",$username,$password) or die "Could not connect: $DBI::errstr";

my $gtfs = GTFS->new($dbh);

$dbh->disconnect;
