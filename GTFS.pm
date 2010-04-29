#!/usr/bin/perl -w
use strict;

package GTFS;

use Data::Dumper;

use Stop qw(@_stops_reqcols @_stops_optcols);
use Trip;
use Route;
use Pattern qw(@_patterns_reqcols);
use List::Compare;

sub new {
	my $proto = shift;
    my $dbh = shift;
    my $optref = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
    $self->{database} = $dbh;
    $self->{options} = $optref;
	bless($self, $class);
    $self->initialize if $self->{options}{loaddata};
    return $self;
}

sub initialize {
    my $self = shift;
    $self->{stops} = $self->getStopsfromDB();
    $self->{trips} = $self->getTripsfromDB();
    $self->{routes} = $self->getRoutesfromDB();
    $self->get_patterns() if $self->{options}{patterns};
}

sub get_patterns {
    my $self = shift;
    my $dbh = $self->{database};
    $self->{patterns} = {};

    # analyze the trips and routes to find the patterns
    my $patternquery = "SELECT stop_sequence, stop_id FROM stop_times WHERE trip_id = ? ORDER BY stop_sequence";
    my $sth = $dbh->prepare($patternquery);
    my $pattern_id = 1;

    # foreach my $route (sort {$a->route_id <=> $b->route_id} values %{ $self->{routes} }) {
    foreach my $route ( values %{ $self->{routes} }) {
    #foreach my $route ( @{ $self->{routes} }{1 .. 10}) {
        my $route_patterns = {};
        foreach my $trip_id ($route->trips) {
            my $trip = $self->{trips}{$trip_id};
            my (@stoporder, @stoplist);
            $sth->execute($trip->trip_id);

            while (my ($stop_sequence, $stop_id) = $sth->fetchrow) {
                push @stoporder, $stop_sequence;
                push @stoplist, $stop_id;
            }
            
            my $pattern = Pattern->new( {
                    pattern_id      =>  $pattern_id,
                    TRIP    =>  $trip_id,
                    route_id   =>  $route->route_id,
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

                    $pattern->pattern_id($pattern_id);
                    $route_patterns->{$pattern_id} = $pattern;
                    print "Found a new pattern: " . $pattern->pattern_id . "\n";

                    my $length = $#stoporder;
                    my @dist = (0);
                    for (my $i = 1; $i <= $length; $i++) {
                        my $a = $self->{stops}{$stoplist[$i-1]};
                        my $b = $self->{stops}{$stoplist[$i]};
                        push @dist, ($dist[$i-1] + $a->twostopdist($b));
                    }
                    $pattern->distances(\@dist);
                    $pattern->totaldist($dist[-1]);
                    ++$pattern_id;
            }

            $self->{trips}{$trip_id}{pattern} = $pattern_id; 
        }

        $route->push_patterns( values %$route_patterns );
        while (my ($id, $pat) = each %$route_patterns) {
            $self->{patterns}{$id} = $pat;
        }

    }
}

sub writePatternstoDB {
    my $self = shift;
    my $dbh = shift || $self->{database};

    $dbh->do("DELETE FROM patterns")
        or die "Could not clear table: $!";

    my $sth = $dbh->prepare("INSERT INTO patterns SET route_id=?, pattern_id=?, stop_sequence=?, stop_id=?, distance=?");

    foreach my $pat (values %{ $self->{patterns} } ) {
        print "Writing Pattern: " . $pat->pattern_id . "\n";
        my $route_id = $pat->route_id;
        my @stops = @{ $pat->stops };
        my @indexes = @{ $pat->indexes };
        my @distances = @{ $pat->distances };
        for (my $i = 0; $i <= $#indexes; $i++) {
            $sth->execute(
                $route_id,
                $pat->{pattern_id},
                $indexes[$i],
                $stops[$i],
                $distances[$i]
            )
                or die "Could not insert data: $!";
        }
    }
}

sub getStopsfromDB {
    my $self = shift;
    return Stop->fromDB($self->{database});
}

sub writeStopstoDB {
    my $self = shift;
    my $dbh = shift || $self->{database};

    $dbh->do("DELETE FROM stops") or die "Could not delete all stops";

    foreach my $stop (values %{$self->{stops}}) {
        $stop->toDB($dbh);
    }
}

sub getTripsfromDB {
    my $self = shift;
    return Trip->fromDB($self->{database});
}

sub writeTripstoDB {
    my $self = shift;
    my $dbh = shift || $self->{database};

    $dbh->do("DELETE FROM trips") or die "Could not delete all trips";

    foreach my $trip (values %{$self->{trips}}) {
        $trip->toDB($dbh);
    }
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

sub writeRoutestoDB {
    my $self = shift;
    my $dbh = shift || $self->{database};

    $dbh->do("DELETE FROM routes") or die "Could not delete all routes";

    foreach my $route (values %{$self->{routes}}) {
        $route->toDB($dbh);
    }
}

sub writeAlltoDB {
    my $self = shift;
    my $dbh = shift || $self->{database};

    $self->writeStopstoDB($dbh);
    $self->writeTripstoDB($dbh);
    $self->writeRoutestoDB($dbh);
}

sub transfertable {
    my $self = shift;
    my $tablename = shift;
    my $dbhout = shift;
    my $dbhin = shift || $self->{database};

    print "Inserting $tablename into Database\n";

    my $sthin = $dbhin->prepare_cached("SELECT * FROM $tablename");
    $sthin->execute;
    my @fieldslist = @{ $sthin->{"NAME_lc"} };

    my $fieldstring = (join "=?, ", @fieldslist) . "=?";

    $dbhout->do("DELETE FROM $tablename");
    my $sthout = $dbhout->prepare_cached("INSERT INTO $tablename SET $fieldstring");

    while (my $data = $sthin->fetchrow_hashref()) {
        foreach my $datum (values %{ $data} ) {
            if ($datum eq '') { undef $datum }
        }
        $sthout->execute( @{$data}{@fieldslist} );
    }
}


1;
