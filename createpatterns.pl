#!/usr/bin/perl -w
use strict;
use DBI;
use Route;
use Trip;
use Stop;
use Pattern;

#############################################################################
#parameters for the sql database
my $DB_host = "localhost";
my $DB_database = "wmata_gtfs";
my $DB_username = "mperkins";
my $DB_password = "secret";

############################################################################
#connect to the database using the parameters
my $dbh = DBI->connect( "DBI:mysql:database=$DB_database;host=$DB_host",
    "$DB_username",
    "$DB_password",
    {PrintError=>1, RaiseError => 1}) 
or
    die("Failed Connecting to the database ".
        "(error number $DBI::err):$DBI::errstr\n");

#############################################################################
#   %routes is a hash where the keys are route_id's
#   and the values are the corresponding route objects
#############################################################################

print "Processing routes ";
my %routes = Route->fromDB($dbh);
print "\n";

#############################################################################
#   %trips is a hash where the keys are trip_id's
#   and the values are the corresponding trip objects
#############################################################################

print "Processing trips ";
my %trips = Trip->fromDB($dbh);

foreach my $trip (values %trips) {
    $routes{$trip->route_id}->push_trips($trip->trip_id);
}
print "\n";

#############################################################################
#   %stops is a hash where the keys are stop_id's
#   and the values are the corresponding stop objects
#############################################################################

print "Processing stops ";
my %stops = Stop->fromDB($dbh);
print "\n";

#############################################################################
#   %patterns is a hash where the keys are stop_id's
#   and the values are the corresponding stop objects
#
#   Stop objects contain ID, LAT, LON,
#   and CENTERDIST, a distance to an arbitrary center of town
#   See Stop.pm
#############################################################################

print "Finding patterns\n";

open(OUTPUT, '>', "output/output.txt") 
    or die "Could not open output file for writing: $!\n";
open(PATOUT, ">", "output/patterns.csv") 
    or die "Could not open patterns outfile: $!\n";

print PATOUT    "route_id, pattern_id, stop_sequence, stop_id, distance\n";

my $patternquery = "select stop_sequence, stop_id from stop_times where trip_id = ? order by stop_sequence";
my $sth = $dbh->prepare($patternquery);

my $tripinsertquery = "UPDATE trips SET pattern_id = ? WHERE trip_id = ?";
my $tripq = $dbh->prepare($tripinsertquery);

my $pattern_id = 1;

foreach my $route (sort {$a->route_id <=> $b->route_id} values %routes) {
#foreach my $route (@routes{qw(40 260 159 106 167 312)}) {
    my %patterns;
    foreach my $trip_id ($route->trips) {
        my $trip = $trips{$trip_id};
        my (@stoporder, @stoplist);
        $sth->execute($trip->trip_id);

        while (my ($stop_sequence, $stop_id) = $sth->fetchrow) {
            push @stoporder, $stop_sequence;
            push @stoplist, $stop_id;
        }
        
        my $pattern = Pattern->new( {
                pattern_id      =>  $pattern_id,
                route_id   =>  $route->route_id,
                STOPS   =>  \@stoplist,
                INDEXES =>  \@stoporder,
                COUNT   =>  1,          #number of trips that use this pattern
        } );

        #check to see if this pattern we just created
        #matches one that already exists
        
        if ((my $matchpattern) = grep { $pattern->isequal($_) } values %patterns) {

                #increase the count of the matched pattern
                #and update the pattern id

                $matchpattern->{COUNT}++;
                $pattern->pattern_id($matchpattern->pattern_id);

        } else {

                #increment pattern_id,
                #change the current pattern_id,
                #and add it to the %patterns hash

                $patterns{$pattern->pattern_id($pattern_id++)} = $pattern;
                print "Found a new pattern: " . $pattern->pattern_id . "\n";

        }

        #now let's update the sql database linking this trip
        #to a particular pattern

        $tripq->execute($pattern_id, $trip_id) 
            or die "Could not execute trip insertion query";

    }

    $route->push_patterns( values %patterns );
    print $route->route_short_name . " Completed!\n";

    print OUTPUT "\n";
    print OUTPUT "Finished " . $route->route_id 
        . " " . $route->route_short_name . "\n";

    foreach my $i (sort {$a->pattern_id <=> $b->pattern_id} values %patterns) {
        print OUTPUT "Pattern: " . $i->pattern_id 
            . "\tTrip: " . $i->trip 
            . "\tStops: " .  ($#{ $i->{STOPS} } + 1) 
            . "\tFirst: " . $i->{STOPS}[0] 
            . "\tLast: " . $i->{STOPS}[-1] 
            . "\tCount: " . $i->{COUNT} 
            . "\n";
    }
}


#print out a csv file that can be sourced into sql
#I'd do this for the trips, but it was so large it couldn't be inserted
foreach my $route (sort {$a->route_id <=> $b->route_id} values %routes) {
    foreach my $pattern (sort {$a->pattern_id <=> $b->pattern_id} $route->patterns) {

        my $length = $#{$pattern->indexes};

        my @dist = (0);

        my @stopids = $pattern->stops;


        for (my $i = 1; $i <= $length; $i++) {
            my $a = $stops{$stopids[$i-1]};
            my $b = $stops{$stopids[$i]};
            push @dist, ($dist[$i-1] + $a->twostopdist($b));
        }

        $pattern->distances(\@dist);
        $pattern->totaldist($dist[-1]);

        for (my $i = 0; $i <= $length; $i++) {
            print PATOUT join(',', 
                $route->route_id, 
                $pattern->pattern_id, 
                $pattern->{INDEXES}[$i], 
                $pattern->{STOPS}[$i], 
                $pattern->{DISTANCES}[$i])
                . "\n";
       }

    }
}

close PATOUT;
close OUTPUT;
$sth->finish;
$tripq->finish;
$dbh->disconnect;
