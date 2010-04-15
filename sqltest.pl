#!/usr/bin/perl -w
use strict;
use DBI;
use Route;
use Stop;
use Pattern;

#############################################################################
#parameters for the sql database
my $DB_host = "localhost";
my $DB_database = "wmata_gtfs";
my $DB_username = "anonymous";
my $DB_password = "";

#############################################################################
# KML file
my $KMLinfile = "input/metroroutesin.kml";
my $KMLoutfile = "output/metroroutesout.kml";

############################################################################
#connect to the database using the parameters
my $dbh = DBI->connect( "DBI:mysql:database=$DB_database;host=$DB_host", "$DB_username", "$DB_password", { PrintError=>1, RaiseError => 1 }) 
	or
	die("Failed Connecting to the database ".
		"(error number $DBI::err):$DBI::errstr\n");

print "Loading Routes\n";
my %routehash = Route->LoadFromDB($dbh);

print "Loading Stops\n";
my %stophash = Stop->LoadFromDB($dbh);

print "Loading Trips\n";
my %triphash = Trip->LoadFromDB($dbh);

print "Finding Patterns ";

my $PATTERNQUERY = "SELECT DISTINCT
	route_id,
	pattern_id
	FROM patterns";

$sth = $dbh->prepare($PATTERNQUERY);
$sth->execute;

my %patterns;

while (my ($ROUTE, $ID) = $sth->fetchrow) {
	my $data = {
		ROUTE => $ROUTE,
		ID => $ID,
	};

	my $pattern = Pattern->new;
	$pattern->initialize($data);
	$patterns{$ID} = $pattern;
	print "$ID\n";
}

$PATTERNQUERY = "SELECT stop_sequence, stop_id FROM patterns WHERE pattern_id = ?";

$sth = $dbh->prepare($PATTERNQUERY);

foreach my $pattern (sort {$a->id <=> $b->id} values %patterns) {
    $sth->execute($pattern->id);
    while (my ($stop_sequence, $stop_id) = $sth->fetchrow) {
        $pattern->addstop($stop_id);
        $pattern->addindex($stop_sequence);
    }
	print $pattern->id . "\n";
}
        
print "\n";

open(KMLIN, "<", $KMLinfile) 
	or die("Could not open KML infile $KMLinfile!");
open(KMLOUT, ">", $KMLoutfile) 
	or die("Could not open KML outfile $KMLoutfile!");

while (<KMLIN>) {
	last if (/<!-- #.*-->/);
	print KMLOUT;
}

foreach my $p (sort {$a->id <=> $b->id} values %patterns) {
	my $r_id = $p->route;
    my $r = $routehash{$r_id};
	my $longname = $r->longname;
	my $name = $r->name;

	#kml header for a route
	print KMLOUT <<"EOT";
		<Placemark>
			<name>$name</name>
			<description>$longname</description>
			<styleUrl>\#blueLine</styleUrl>
			<LineString>
				<tesselate>1</tesselate>
				<coordinates>
EOT

	foreach my $s_id ($p->stops) {
        my $s = $stophash{$s_id};
		print KMLOUT $s->lon . "," . $s->lat . "\n";
	}
	print KMLOUT <<"EOT";
				</coordinates>
			</LineString>
		</Placemark>
EOT

}

while (<KMLIN>) {
	print KMLOUT;
}

$sth->finish;
$dbh->disconnect;
