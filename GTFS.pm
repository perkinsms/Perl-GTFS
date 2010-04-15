#!/usr/bin/perl -w
use strict;

package GTFS;

use Stop;
use Trip;
use Route;
use Pattern;

sub new {
	my $proto = shift;
    my $dbh = shift;
    my $optref = shift or undef;
	my $class = ref($proto) || $proto;
	my $self = {};
    $self->{database} = $dbh;
    $self->{options} = $optref;
	bless($self, $class);
    $self->initialize;
}

sub get_patterns {
    my $dbh = $self->{database};
    my $routes = $self->{routes};
    my $trips = $self->{trips};
    my $stops = $self->{stops};

    # analyze the trips and routes to find the patterns
    my $patternquery = "select stop_sequence, stop_id from stop_times where trip_id = ? order by stop_sequence";
    my $sth = $dbh->prepare($patternquery);

    my $tripinsertquery = "UPDATE trips SET pattern_id = ? WHERE trip_id = ?";
    my $trip_st = $dbh->prepare($tripinsertquery);

    my $pattern_id = 0;

    foreach my $route (sort {$a->route_id <=> $b->route_id} values %$routes) {
#foreach my $route (@$routes{qw(40 260 159 106 167 312)}) {
        my $patterns = {};
        foreach my $trip_id ($route->trips) {
            my $trip = $trips->{$trip_id};
            my (@stoporder, @stoplist);
            $sth->execute($trip->trip_id);

            while (my ($stop_sequence, $stop_id) = $sth->fetchrow) {
                push @stoporder, $stop_sequence;
                push @stoplist, $stop_id;
            }
            
            my $pattern = Pattern->new( {
                    pattern_id      =>  $pattern_id,
                    TRIP    =>  $trip_id,
                    ROUTE   =>  $route->route_id,
                    STOPS   =>  \@stoplist,
                    INDEXES =>  \@stoporder,
                    COUNT   =>  1,          #number of trips that use this pattern
            } );

            #check to see if this pattern we just created
            #matches one that already exists
            
            if ((my $matchpattern) = grep { $pattern->isequal($_) } values %$patterns) {

                    #increase the count of the matched pattern
                    #and update the pattern id

                    $matchpattern->{COUNT}++;
                    $pattern->pattern_id($matchpattern->pattern_id);

            } else {

                    #increment pattern_id,
                    #change the current pattern_id,
                    #and add it to the %patterns hash

                    ++$pattern_id;
                    $pattern->pattern_id($pattern_id);
                    $patterns->{$pattern_id} = $pattern;
                    print "Found a new pattern: " . $pattern->pattern_id . "\n";

            }

            #now let's update the sql database linking this trip
            #to a particular pattern

            $trip_st->execute($pattern_id, $trip_id) 
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

sub initialize {
    my $self = shift;
    my $dbh = $self->{database};

    my @required_tables = qw(agency stops routes trips stop_times calendar);
    my @optional_tables = qw(calendar_dates fare_rules fare_attributes shapes frequencies transfers);
    my @built_tables = qw(patterns);

    my @tables = $dbh->tables();

    foreach my $table (@required_tables) {
        if (grep {$table eq $_} @tables) {
            print "$table is present\n";
        } else {
            die "Required table $table is missing\n";
        }
    }

    foreach my $table (@optional_tables) {
        if (grep {$table eq $_} @tables) {
            print "optional table $table is present\n";
        } else {
            print "optional table $table not present\n";
        }
    }

    foreach my $table (@built_tables) {
        if (grep {$table eq $_ } @tables) {
            print "built table $table is present\n";
        } else {
            print "built table $table not present\n";
        }
    }

    # Ensure stops table has adequate columns
    # required columns: 
    # stop_id
    # stop_name
    # stop_lat
    # stop_lon

