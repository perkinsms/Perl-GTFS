#!/usr/bin/perl -w
use strict;
use GTFS;
use DBI;

my $gtfs_dir = "input/arlington_gtfs";
my $dbh = DBI->connect("DBI:CSV:f_dir=$gtfs_dir;f_ext=.txt;csv_sep_char=,;csv_quote_char=\"") or die "Could not connect: $DBI::errstr";

my $gtfs_data = GTFS->new($dbh);
my $stops = $gtfs_data->getStopsfromDB();

$dbh->disconnect;
