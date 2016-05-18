package OracleOpenSessions::SQL;

#===============================================================================
#
#         FILE: SQL.pm
#      PACKAGE: SQL
#
#  DESCRIPTION: SQL OracleOpenSessions
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Denis Immoos (<denisimmoos@gmail.com>)
#    AUTHORREF: Senior Linux System Administrator (LPIC3)
#      VERSION: 1.0
#      CREATED: 01/27/2016 01:03:34 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

use DBI;

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self;
} 

sub error {
    my $caller = shift;
    my $msg = shift || $caller;
    die( "ERROR($caller): $msg" );
}

sub verbose {
    my $caller = shift;
    my $msg = shift || $caller;
    print( "INFO($caller): $msg" . "\n" );
}


sub sql {

    my $self = shift;
    my $ref_Options = shift;
    my %Options = %{ $ref_Options };
    my $caller = (caller(0))[3];


	my $sql_open_sessions = 'SELECT count(*) AS OPEN_SESSIONS FROM v$session';
	my $sql_max_sessions = 'SELECT value AS MAX_SESSIONS from v$parameter WHERE name = \'sessions\''; 

    my $dbh = DBI->connect("dbi:Oracle:host=$Options{'hostname'};sid=$Options{'sid'}", $Options{'username'}, $Options{'password'})

    or die( $DBI::errstr . "\n");

    my $sth = $dbh->prepare($sql_open_sessions);
       $sth->execute;

	while ( my $row = $sth->fetchrow_hashref ) {
		$Options{'OPEN_SESSIONS'}= $row->{'OPEN_SESSIONS'};
	}

	# max_sessions
    $sth = $dbh->prepare($sql_max_sessions);
    $sth->execute;

	while ( my $row = $sth->fetchrow_hashref ) {
		$Options{'MAX_SESSIONS'}= $row->{'MAX_SESSIONS'};
	}

	return  %Options;

}



1;

__END__

=head1 NAME

SQL - SQL OracleOpenSessions 

=head1 SYNOPSIS

use SQL;

my $object = SQL->new();

=head1 DESCRIPTION

This description does not exist yet, it
was made for the sole purpose of demonstration.

=head1 LICENSE

This is released under the GPL3.

=head1 AUTHOR

Denis Immoos - <denisimmoos@gmail.com>, Senior Linux System Administrator (LPIC3)

=cut


