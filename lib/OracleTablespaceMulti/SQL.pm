package OracleTablespaceMulti::SQL;

#===============================================================================
#
#         FILE: SQL.pm
#      PACKAGE: SQL
#
#  DESCRIPTION: SQL OracleTablespaceMulti
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


	my $sql = '
			SELECT T1.TABLESPACE_NAME, "PCT_USED", "ALLOCATED", "USED", "FREE", "DATAFILES", T2.AUTOEXTENSIBLE FROM (
			SELECT "TABLESPACE_NAME", "PCT_USED", "ALLOCATED", "USED", "FREE", "DATAFILES" FROM(
			SELECT a.tablespace_name,
			ROUND(((c.bytes-nvl(b.bytes,0))/c.bytes)*100,2) PCT_USED,
			c.bytes/1024/1024 allocated,
			round(c.bytes/1024/1024-nvl(b.bytes,0)/1024/1024,2) used,
			round(nvl(b.bytes,0)/1024/1024,2) free,
			c.datafiles
			FROM dba_tablespaces a,
			( SELECT tablespace_name, SUM(bytes) bytes FROM dba_free_space GROUP BY tablespace_name ) b,
			( select count(1) datafiles, SUM(bytes) bytes, tablespace_name from dba_data_files GROUP BY tablespace_name ) c
			WHERE b.tablespace_name (+) = a.tablespace_name
			AND c.tablespace_name (+) = a.tablespace_name
			ORDER BY nvl(((c.bytes-nvl(b.bytes,0))/c.bytes),0) DESC
			)
			) T1,
			( select distinct TABLESPACE_NAME,AUTOEXTENSIBLE from dba_data_files ) T2
			WHERE
			T1.TABLESPACE_NAME = T2.TABLESPACE_NAME
			';


    my $dbh = DBI->connect("dbi:Oracle:host=$Options{'hostname'};sid=$Options{'sid'}", $Options{'username'}, $Options{'password'})

    or die( $DBI::errstr . "\n");

    my $sth = $dbh->prepare($sql);
       $sth->execute;

	while ( my $row = $sth->fetchrow_hashref ) {
		
		# '' => NULL
		map { $row->{$_} = "NULL" unless defined ($row->{$_}); } keys(%{$row});
		$Options{'TS'}{$row->{'TABLESPACE_NAME'}} = $row;
	}

	return  %Options;

}



1;

__END__

=head1 NAME

SQL - SQL OracleTablespaceMulti 

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


