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

use Moose;
my @reqcols = qw/route_id service_id trip_id/;
my @optcols = qw/trip_headsign trip_short_name direction_id block_id shape_id pattern_id/;

has 'route_id' => (is => 'ro', isa => 'Str', default => '');
has 'service_id' => (is => 'ro', isa => 'Str', default => '');
has 'trip_id' => (is => 'ro', isa => 'Str', default => '');
has 'trip_headsign' => (is => 'ro', isa => 'Maybe[Str]', default => '', lazy => 1);
has 'trip_short_name' => (is => 'ro', isa => 'Maybe[Str]', default => '', lazy => 1);
has 'direction_id' => (is => 'ro', isa => 'Maybe[Int]', default => 0);
has 'block_id' => (is => 'ro', isa => 'Maybe[Str]', default => '', lazy => 1);
has 'shape_id' => (is => 'ro', isa => 'Maybe[Str]', default => '', lazy => 1);
has 'pattern_id' => (is => 'rw', isa => 'Maybe[Str]', default => '', lazy => 1);
has 'stops' => (is => 'rw', isa => 'Maybe[ArrayRef]', lazy => 1, default => sub { [] });

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
__PACKAGE__->meta->make_immutable;
no Moose;

1;
