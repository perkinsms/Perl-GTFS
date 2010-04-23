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

my @reqcols = qw/route_id service_id trip_id/;
my @optcols = qw/trip_headsign trip_short_name direction_id block_id shape_id/;

sub new {
	my $proto = shift;
	my $data = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{route_id} = $data->{route_id} or die "No defined route_id in trips: $!";
	$self->{service_id} = $data->{service_id} or die "No defined service_id in trips: $!";
	$self->{trip_id} = $data->{trip_id} or die "No defined trip_id in trips: $!";
	$self->{trip_headsign} = $data->{trip_headsign} if $data->{trip_headsign};
	$self->{trip_short_name} = $data->{trip_short_name} if $data->{trip_short_name};
	$self->{direction_id} = $data->{direction_id} if $data->{direction_id};
	$self->{block_id} = $data->{block_id} if $data->{block_id};
	$self->{shape_id} = $data->{shape_id} if $data->{shape_id};
	$self->{pattern_id} = $data->{pattern_id} if $data->{pattern_id};
	$self->{STOPS} = [];
	return bless($self, $class);
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

    my $sth = $dbh->prepare("SELECT * FROM trips") 
        or die "Could not prepare trips query!";
    $sth->execute;

    while (my $datahash = $sth->fetchrow_hashref("NAME_lc")) {
        my $id = $datahash->{trip_id};
        $trips{$id} = $class->new($datahash);
    }
    return \%trips;
}

sub toDB {
    my $self = shift;
    my $dbh = shift;
    my $tablename = "trips";
    my @fieldslist = (@reqcols, @optcols);
    my $columnstring = (join "=?, ", @fieldslist) . "=?";

    my $sth = $dbh->prepare_cached("INSERT INTO $tablename SET $columnstring");
    $sth->execute( @{$self}{@fieldslist} ) 
        or die "Could not insert into $tablename";
}

1;
