#!/usr/bin/perl -w
use strict;
#############################################################################
#  Route - implement GTFS minimum functionality for routes
#
#  Object Attributes (all GTFS compliant)
#  route_id
#  agency_id
#  route_short_name
#  route_long_name
#  route_desc
#  route_type
#  route_url
#  route_color
#  route_text_color
#
#  Attributes not part of GTFS
#  PATTERNS
#  TRIPS
#
#  Methods:
#  new - create a new Route object, optional data

package Route;

my @reqcols = qw/route_id route_short_name route_name route_type/;
my @optcols = qw/agency_id route_desc route_url route_color route_text_color/;

sub new {
	my $proto = shift;
    my $data = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{route_id} = ($data->{route_id} or undef);
	$self->{agency_id} = ($data->{agency_id} or undef);
	$self->{route_short_name} = ($data->{route_short_name} or undef);
	$self->{route_long_name} = ($data->{route_long_name} or undef);
	$self->{route_desc} = ($data->{route_desc} or undef);
	$self->{route_type} = ($data->{route_type} or undef);
	$self->{route_url} = ($data->{route_url} or undef);
	$self->{route_color} = ($data->{route_color} or undef);
	$self->{route_text_color} = ($data->{route_text_color} or undef);
    $self->{PATTERNS} = (\@{$data->{PATTERNS} } or []);
    $self->{TRIPS} = (\@{$data->{TRIPS} } or []);
	return bless($self, $class);
}

sub route_id {
	my $self = shift;
	if (@_) { $self->{route_id} = shift }
	return $self->{route_id};
}

sub agency_id {
	my $self = shift;
	if (@_) { $self->{agency_id} = shift }
	return $self->{agency_id};
}

sub route_short_name {
	my $self = shift;
	if (@_) { $self->{route_short_name} = shift }
	return $self->{route_short_name};
}

sub route_long_name {
	my $self = shift;
	if (@_) { $self->{route_long_name} = shift }
	return $self->{route_long_name};
}

sub route_desc {
	my $self = shift;
	if (@_) { $self->{route_desc} = shift }
	return $self->{route_desc};
}

sub route_type {
	my $self = shift;
	if (@_) { $self->{route_type} = shift }
	return $self->{route_type};
}

sub route_url {
	my $self = shift;
	if (@_) { $self->{route_url} = shift }
	return $self->{route_url};
}

sub route_color {
	my $self = shift;
	if (@_) { $self->{route_color} = shift }
	return $self->{route_color};
}

sub route_text_color {
	my $self = shift;
	if (@_) { $self->{route_text_color} = shift }
	return $self->{route_text_color};
}

sub patterns { 
	my $self = shift;
	if (@_) { $self->{PATTERNS} = @_; }
	return @{ $self->{PATTERNS} };
}

sub push_patterns {
	my $self = shift;
	my @patterns = @_;
	push @{ $self->{PATTERNS} }, @patterns;
	return @{ $self->{PATTERNS}};
}

sub trips { 
	my $self = shift;
	if (@_) { $self->{TRIPS} = @_; }
	return @{ $self->{TRIPS} };
}

sub push_trips {
	my $self = shift;
	my @trips = @_;
	push @{ $self->{TRIPS} }, @trips;
	return @{ $self->{TRIPS}};
}

sub fromDB {
    my $class = shift;
    my $dbh = shift;
    my %routes;

    my $sth = $dbh->prepare("SELECT * FROM routes");
    $sth->execute;

    while (my $datahash = $sth->fetchrow_hashref("NAME_lc")) {
        my $id = $datahash->{route_id};
        $routes{$id} = $class->new($datahash);
    }
    $sth->finish;
    return \%routes;
}

sub toDB {
    my $class = shift;
    my $dbh = shift;
    my $routehashref = shift;
    my %routes = %{$routehashref};

    $dbh->do("DROP TABLE IF EXISTS routes") or die "Could not drop table routes";
    $dbh->do("CREATE TABLE routes (route_id varchar(20), agency_id varchar(20), route_short_name varchar(60), route_long_name varchar(60), route_type int(11))") or die "Could not create table routes";

    my $sth = $dbh->prepare("INSERT INTO routes (route_id, agency_id, route_short_name, route_long_name, route_type) VALUES (?, ?, ?, ?, ?)") or die "Could not prepare statement";

    foreach my $route (sort {$a->{route_id} <=> $b->{route_id} } values %routes) {
        $sth->execute( $route->{route_id},
                       $route->{agency_id},
                       $route->{route_short_name},
                       $route->{route_long_name},
                       $route->{route_type} )
    }

    $sth->finish;

}

1;
