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
    $self->getTripsfromDB();
    $self->getStopsfromDB();
    $self->getRoutesfromDB();
    $self->get_patterns();
    $self->initialize;
}

sub get_patterns {
    my $self = shift;
    my $dbh = $self->{database};
    my $routes = $self->{routes};
    my $trips = $self->{trips};
    my $stops = $self->{stops};

    # analyze the trips and routes to find the patterns
    my $patternquery = "select stop_sequence, stop_id from stop_times where trip_id = ? order by stop_sequence";
    my $sth = $dbh->prepare($patternquery);
    my $pattern_id = 0;

    foreach my $route (sort {$a->route_id <=> $b->route_id} values %$routes) {
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
            $trips->{$trip_id}{pattern} = $pattern_id; 
        }

        $route->push_patterns( values %$patterns );

    }

    foreach my $route (sort {$a->route_id <=> $b->route_id} values %$routes) {
        foreach my $pattern (sort {$a->pattern_id <=> $b->pattern_id} $route->patterns) {

            my $length = $#{$pattern->indexes};
            my @dist = (0);
            my @stopids = $pattern->stops;
            for (my $i = 1; $i <= $length; $i++) {
                my $a = $stops->{$stopids[$i-1]};
                my $b = $stops->{$stopids[$i]};
                push @dist, ($dist[$i-1] + $a->twostopdist($b));
            }
            $pattern->distances(\@dist);
            $pattern->totaldist($dist[-1]);

       }

    }
}

sub getStopsfromDB {
    my $self = shift;
    $self->{stops} = Stop->fromDB($self->{database});
}

sub getTripsfromDB {
    my $self = shift;
    $self->{trips} = Trip->fromDB($self->{database});
}

sub getRoutesfromDB {
    my $self = shift;
    $self->{routes} = Route->fromDB($self->{database});
}

1;
