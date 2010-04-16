#!/usr/bin/perl -w
use strict;
#############################################################################
#  Trip - implement GTFS minimum functionality for trips
#
#  Object Attributes (all GTFS-compliant):
#  route_id
#  service_id
#  trip_id
#  trip_headsign
#  trip_short_name
#  direction_id
#  block_id
#  shape_id
#
#  Other attributes (not part of GTFS)
#  pattern_id
#  STOPS
#
#  Methods:
#  new - create a new Route object, with blank data
#  all object attributes have get/set accessors
#  $number = $self->push_stops( @{list of stops} )
#   returns resulting array STOPS

package Trip;

sub new {
	my $proto = shift;
	my $data = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{route_id} = undef;
	$self->{service_id} = undef;
	$self->{trip_id} = undef;
	$self->{trip_headsign} = undef;
	$self->{trip_short_name} = undef;
	$self->{direction_id} = undef;
	$self->{block_id} = undef;
	$self->{shape_id} = undef;
	$self->{pattern_id} = undef;
	$self->{STOPS} = [];
	bless($self, $class);
    $data and $self->initialize($data);
	return $self;
}

sub initialize {
	my $self = shift;
	my $data = shift;
	$self->{route_id}        = ($data->{route_id} or $self->{route_id});
	$self->{service_id}      = ($data->{service_id} or $self->{service_id});
	$self->{trip_id}         = ($data->{trip_id} or $self->{trip_id});
	$self->{trip_headsign}   = ($data->{trip_headsign} or $self->{trip_headsign});
	$self->{trip_short_name} = ($data->{trip_short_name} or $self->{trip_short_name});
	$self->{direction_id}    = ($data->{direction_id} or $self->{direction_id});
	$self->{block_id}        = ($data->{block_id} or $self->{block_id});
	$self->{shape_id}        = ($data->{shape_id} or $self->{shape_id});
	$self->{pattern_id}      = ($data->{pattern_id} or $self->{pattern_id});
	$self->{STOPS}           = (\@{ $data->{STOPS} }
                            or $self->{STOPS});
}

sub route_id {
	my $self = shift;
	if (@_) { $self->{route_id} = shift }
	return $self->{route_id};
}

sub service_id {
	my $self = shift;
	if (@_) { $self->{service_id} = shift }
	return $self->{service_id};
}

sub trip_id {
	my $self = shift;
	if (@_) { $self->{trip_id} = shift }
	return $self->{trip_id};
}

sub trip_headsign {
	my $self = shift;
	if (@_) { $self->{trip_headsign} = shift }
	return $self->{trip_headsign};
}

sub trip_short_name {
	my $self = shift;
	if (@_) { $self->{trip_short_name} = shift }
	return $self->{trip_short_name};
}

sub direction_id {
	my $self = shift;
	if (@_) { $self->{direction_id} = shift }
	return $self->{direction_id};
}

sub block_id {
	my $self = shift;
	if (@_) { $self->{block_id} = shift }
	return $self->{block_id};
}

sub shape_id {
	my $self = shift;
	if (@_) { $self->{shape_id} = shift }
	return $self->{shape_id};
}

sub pattern_id {
	my $self = shift;
	if (@_) { $self->{pattern_id} = shift }
	return $self->{pattern_id};
}

sub stops { 
	my $self = shift;
	if (@_) { $self->{STOPS} = @_; }
	return @{ $self->{STOPS} };
}

sub push_stops {
	my $self = shift;
	my @stops = @_;
	push @{ $self->{STOPS} }, @stops;
	return @{ $self->{STOPS}};
}

sub fromDB {

    my $class = shift;
    my $dbh = shift;

    my %trips;

    my $sth = $dbh->prepare("SELECT * FROM trips");
    $sth->execute();
    print join ', ', @{$sth->{NAME_lc}};

    my $TRIPSQUERY = "SELECT route_id, service_id, trip_id FROM trips";
    $sth = $dbh->prepare($TRIPSQUERY);
    $sth->execute;

    while (my ($route_id, $service_id, $trip_id) = $sth->fetchrow()) {
        $trips{$trip_id} = $class->new( { 
                route_id => $route_id,
                service_id => $service_id,
                trip_id => $trip_id,
        });
    }

    return \%trips;
}

1;
