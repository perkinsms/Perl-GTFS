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
use Moose;

my @reqcols = qw/route_id route_short_name route_long_name route_type/;
my @optcols = qw/agency_id route_desc route_url route_color route_text_color/;

has 'route_id' => (is => 'ro', isa => 'Str', default => '');
has 'route_short_name' => (is => 'ro', isa => 'Maybe[Str]', default => '');
has 'route_long_name' => (is => 'ro', isa => 'Maybe[Str]', default => '');
has 'route_type' => (is => 'ro', isa => 'Int', default => 0);
has 'agency_id' => (is => 'ro', isa => 'Maybe[Str]', default=> '', lazy => 1);
has 'route_desc' => (is => 'ro', isa => 'Maybe[Str]', default=> '', lazy => 1);
has 'route_url' => (is => 'ro', isa => 'Maybe[Str]', default=> '', lazy => 1);
has 'route_color' => (is => 'ro', isa => 'Maybe[Str]', default=> '', lazy => 1);
has 'route_text_color' => (is => 'ro', isa => 'Maybe[Str]', default=> '', lazy => 1);
has 'patterns' => (is => 'rw', isa => 'Maybe[ArrayRef[Pattern]]');
has 'trips' => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');

sub push_patterns {
	my $self = shift;
	my @patterns = @_;
	push @{ $self->{patterns} }, @patterns;
	return @{ $self->{patterns}};
}

sub push_trips {
	my $self = shift;
	my @trips = @_;
	push @{ $self->{trips} }, @trips;
	return @{ $self->{trips}};
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
    my $self = shift;
    my $dbh = shift;
    my $tablename = "routes";
    my @fieldslist = (@reqcols, @optcols);
    my $columnstring = (join "=?, ", @fieldslist) . "=?";

    my $sth = $dbh->prepare_cached("INSERT INTO $tablename SET $columnstring");
    $sth->execute( @{$self}{@fieldslist} ) 
        or die "Could not insert into $tablename";
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
