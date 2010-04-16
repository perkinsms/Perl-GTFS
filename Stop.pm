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

my $PI = 3.14159;

my @fieldslist = qw(stop_id stop_code stop_name stop_desc stop_lat stop_lon zone_id stop_url location_type parent_station CENTERDIST);

sub new {
	my $proto = shift;
	my $data = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{stop_id} = $data->{stop_id} or warn "No Stop ID provided: $!";
	$self->{stop_code} = ($data->{stop_code} or undef);
	$self->{stop_name} = $data->{stop_name} or warn "No Stop Name provided: $!";
	$self->{stop_desc} = ($data->{stop_desc} or undef);
	$self->{stop_lat} = $data->{stop_lat} or warn "No Stop Lat provided: $!";
	$self->{stop_lon} = $data->{stop_lon} or warn "No Stop Lon provided: $!";
	$self->{zone_id} = ($data->{zone_id} or undef);
	$self->{stop_url} = ($data->{stop_url} or undef); 
	$self->{location_type} = ($data->{location_type} or undef);
	$self->{parent_station} = ($data->{parent_station} or undef);
	$self->{CENTERDIST} = ($data->{CENTERDIST} || 999999);
	bless($self, $class);
	return $self;
}

sub stop_id {
	my $self = shift;
	if (@_) { $self->{stop_id} = shift }
	return $self->{stop_id};
}

sub stop_code {
	my $self = shift;
	if (@_) { $self->{stop_code} = shift }
	return $self->{stop_code};
}

sub stop_name {
	my $self = shift;
	if (@_) { $self->{stop_name} = shift }
	return $self->{stop_name};
}

sub stop_desc {
	my $self = shift;
	if (@_) { $self->{stop_desc} = shift }
	return $self->{stop_desc};
}

sub stop_lat {
	my $self = shift;
	if (@_) { $self->{stop_lat} = shift }
	return $self->{stop_lat};
}

sub stop_lon {
	my $self = shift;
	if (@_) { $self->{stop_lon} = shift }
	return $self->{stop_lon};
}

sub zone_id {
	my $self = shift;
	if (@_) { $self->{zone_id} = shift }
	return $self->{zone_id};
}

sub stop_url {
	my $self = shift;
	if (@_) { $self->{stop_url} = shift }
	return $self->{stop_url};
}

sub location_type {
	my $self = shift;
	if (@_) { $self->{location_type} = shift }
	return $self->{location_type};
}

sub parent_station {
	my $self = shift;
	if (@_) { $self->{parent_station} = shift }
	return $self->{parent_station};
}

sub centerdist {
	my $self = shift;
	if (@_) { $self->{CENTERDIST} = shift }
	return $self->{CENTERDIST};
}

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

sub Dump {
	my $self = shift;
	print Dumper($self);
}

sub fromDB {
    my $class = shift;
    my $dbh = shift;

    my %stops;

    my $sth = $dbh->prepare("SELECT * FROM stops");
    $sth->execute();
    print join ', ', @{$sth->{NAME_lc}};

    my $STOPSQUERY = "SELECT stop_id, stop_name, stop_lat, stop_lon FROM stops";
    $sth = $dbh->prepare($STOPSQUERY) or die "Could not prepare stops query!";
    $sth->execute;

    while (my ($stop_id, $stop_name, $stop_lat, $stop_lon) = $sth->fetchrow()) {
        $stops{$stop_id} = $class->new( { 
                stop_id => $stop_id,
                stop_name => $stop_name,
                stop_lat => $stop_lat,
                stop_lon => $stop_lon,
        });
    }

    $sth->finish;

    return \%stops;
}

sub toDB {
    my $class = shift;
    my $dbh = shift;
    my $stopref = shift;
    my %stops = %{$stopref};

    $dbh->do("DROP TABLE IF EXISTS stops") or die "Could not drop table stops";
    $dbh->do("CREATE TABLE stops (stop_id varchar(20), stop_name varchar(20), stop_desc varchar(60), stop_lat varchar(20), stop_lon varchar(20), zone_id varchar(20))") or die "Could not create table stops";

    my $QUERY = "INSERT INTO stops ( stop_id, stop_name, stop_desc, stop_lat, stop_lon, zone_id ) VALUES ( ?, ?, ?, ?, ?, ? )";

    my $sth = $dbh->prepare($QUERY);

    foreach my $stop (sort {$a->{stop_id} <=> $b->{stop_id} } values %stops) {
        $sth->execute( $stop->{stop_id},
                       $stop->{stop_name},
                       $stop->{stop_desc},
                       $stop->{stop_lat},
                       $stop->{stop_lon},
                       $stop->{zone_id} )
    } 

}

1;
