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
    my $optref = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
    $self->{database} = $dbh;
    $self->{options} = $optref;
	bless($self, $class);
    $self->initialize;
    return $self;
}

sub initialize {
    my $self = shift;
    $self->{stops} = $self->getStopsfromDB();
    $self->{trips} = $self->getTripsfromDB();
    $self->{routes} = $self->getRoutesfromDB();
    $self->get_patterns();
}

sub get_patterns {
    my $self = shift;
    my $dbh = $self->{database};
    my $routes = $self->{routes};
    my $trips = $self->{trips};
    my $stops = $self->{stops};
    $self->{patterns} = {};

    # analyze the trips and routes to find the patterns
    my $patternquery = "select stop_sequence, stop_id from stop_times where trip_id = ? order by stop_sequence";
    my $sth = $dbh->prepare($patternquery);
    my $pattern_id = 0;

    foreach my $route (sort {$a->route_id <=> $b->route_id} values %$routes) {
        my $route_patterns = {};
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
            
            if ((my $matchpattern) = grep { $pattern->isequal($_) } values %$route_patterns) {

                    #increase the count of the matched pattern
                    #and update the pattern id

                    $matchpattern->{COUNT}++;
                    $pattern->pattern_id($matchpattern->pattern_id);

            } else {

                    #increment pattern_id,
                    #change the current pattern_id,
                    #and add it to the %route_patterns hash

                    ++$pattern_id;
                    $pattern->pattern_id($pattern_id);
                    $route_patterns->{$pattern_id} = $pattern;
                    print "Found a new pattern: " . $pattern->pattern_id . "\n";

            }

            $trips->{$trip_id}{pattern} = $pattern_id; 
        }

        $route->push_patterns( values %$route_patterns );
        while (my ($id, $pat) = each %$route_patterns) {
            $self->{patterns}{$id} = $pat;
        }

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
    return Stop->fromDB($self->{database});
}

sub getTripsfromDB {
    my $self = shift;
    return Trip->fromDB($self->{database});
}

sub getRoutesfromDB {
    my $self = shift;
    my $trips = $self->{trips} || $self->getTripsfromDB();
    $self->{routes} = Route->fromDB($self->{database});
    foreach my $trip (values %$trips) {
        my $route_id = $trip->{route_id};
        $self->{routes}{$route_id}->push_trips($trip->trip_id);
    }
    return $self->{routes}
}

1;
