#!/usr/bin/perl -w
use strict;
#############################################################################
#  Stop - implement GTFS minimum functionality for stops
#
#  Object Attributes (all GTFS compliant)
#  stop_id
#  stop_code
#  stop_name
#  stop_desc
#  stop_lat
#  stop_lon
#  zone_id
#  stop_url
#  location_type
#  parent_station
#
#  Methods:
#  new - create a new Route object, with blank data
#  id - get or set ID attribute
#  name - get or set NAME attribute

package Stop;

use Moose;

my $PI = 3.14159;
my @_stops_reqcols = qw/stop_id stop_name stop_lat stop_lon/;
my @_stops_optcols = qw/stop_code stop_desc zone_id stop_url location_type parent_station/;

has 'stop_id' => (is => 'ro', isa => 'Str', default => '');
has 'stop_code' => (is => 'ro', isa => 'Maybe[Str]', default => '', lazy => 1);
has 'stop_name' => (is => 'ro', isa => 'Str', default => '');
has 'stop_desc' => (is => 'ro', isa => 'Maybe[Str]', default => '', lazy => 1);
has 'stop_lat' => (is => 'ro', isa => 'Num', default => 0);
has 'stop_lon' => (is => 'ro', isa => 'Num', default => 0);
has 'zone_id' => (is => 'ro', isa => 'Maybe[Str]', default => '', lazy => 1);
has 'stop_url' => (is => 'ro', isa => 'Maybe[Str]', default => '', lazy => 1);
has 'location_type' => (is => 'ro', isa => 'Maybe[Int]', default => 0, lazy => 1);
has 'parent_station' => (is => 'ro', isa => 'Maybe[Str]', default => '0', lazy => 1);

sub disttopoint {
	my $self = shift;
	my ($pointlat, $pointlon) = @_[0,1];
	my ($stoplat, $stoplon) = ($self->stop_lat, $self->stop_lon);
	my $disttopoint = twopointdist($pointlat, $pointlon, $stoplat, $stoplon);
	return $disttopoint
}

sub twostopdist {
	# self = stop "A", other = reference to stop "B"
	my $self = shift;
	my $other = shift;
	return ($self->disttopoint($other->stop_lat, $other->stop_lon));
}

sub twopointdist {
	foreach my $angle (@_[0 .. 3]) {
		$angle = $angle * $PI / 180.0;
	}
	my ($la1, $ln1, $la2, $ln2) =  @_[0 .. 3];
	my $X = hvsin($la1 - $la2) + cos($la1) * cos($la2) * hvsin($ln1 - $ln2);
	return (2 * 3958.761 * sqrt($X));
}

sub hvsin {
	my $theta = shift;
	my $result = sin($theta/2.0) * sin($theta/2.0);
	return $result;
}

sub fromDB {
    my $class = shift;
    my $dbh = shift;
    my %stops;

    my $sth = $dbh->prepare("SELECT * FROM stops") 
        or die "Could not prepare stops query!";
    $sth->execute;

    while (my $datahash = $sth->fetchrow_hashref("NAME_lc")) {
        my $id = $datahash->{stop_id};
        $stops{$id} = $class->new($datahash);
    }
    $sth->finish;
    return \%stops;
}

sub toDB {
    my $self = shift;
    my $dbh = shift;
    my $tablename = "stops";
    my @fieldslist = (@_stops_reqcols, @_stops_optcols);
    my $columnstring = (join "=?, ", @fieldslist) . "=?";
    
    my $sth = $dbh->prepare_cached("INSERT INTO $tablename SET $columnstring");

    $sth->execute( @{$self}{@fieldslist} ) 
        or die "Could not insert into $tablename";
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
