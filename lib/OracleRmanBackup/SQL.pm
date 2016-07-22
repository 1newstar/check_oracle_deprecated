package OracleRmanBackup::SQL;

#===============================================================================
#
#         FILE: SQL.pm
#      PACKAGE: SQL
#
#  DESCRIPTION: SQL OracleRmanBackup
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


	my $sql = "SELECT *
	           -- INPUT_TYPE,
			   -- STATUS,
			   -- to_char(START_TIME,'dd/mm/yy hh24:mi') START_TIME,
			   -- to_char(END_TIME,'dd/mm/yy hh24:mi')   END_TIME
			   FROM V\$RMAN_BACKUP_JOB_DETAILS
			   WHERE START_TIME > systimestamp - interval \'$Options{'interval'}\' day";
	
	 if ($Options{'input-type'}) {
		 $sql .= " AND INPUT_TYPE LIKE '%$Options{'input-type'}%'";
	 }

    my $dbh = DBI->connect("dbi:Oracle:host=$Options{'hostname'};sid=$Options{'sid'}", $Options{'username'}, $Options{'password'} )
    or die( $DBI::errstr . "\n");

    my $sth = $dbh->prepare($sql);
       $sth->execute;

	my $count = 0;

	while ( my $row = $sth->fetchrow_hashref ) {
		map { $row->{$_} = "NULL" unless defined ($row->{$_}); } keys(%{$row});
		$Options{'RMAN'}{$count} = $row;
		++$count;
	}
	return  %Options;
}

1;

__END__

=head1 NAME

SQL - SQL OracleRmanBackup 

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


