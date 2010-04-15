#!/usr/bin/perl -w
use strict;
use Stop;
use Route;
use Trip;
use DBI;
use Data::Dumper;

my $gtfs_dir = "input/arlington_gtfs";
my $dbh = DBI->connect("DBI:CSV:f_dir=$gtfs_dir;f_ext=.txt;csv_sep_char=,;csv_quote_char=\"") or die "Could not connect: $DBI::errstr";

my @tables = $dbh->tables();

my @requiredtables = qw(stops foobar routes trips stop_times);

foreach my $name (@requiredtables) {
    grep {$_ eq $name } @tables  and print "$name is present\n";
}

my $sth = $dbh->table_info('%','','');
$sth->dump_results();

my $sth = $dbh->column_info(undef,undef,'routes',undef);
$sth->dump_results();

#my $routes = Route->fromDB($dbh);
#my $trips = Trip->fromDB($dbh);
#my $stops = Stop->fromDB($dbh);

$dbh->disconnect;
