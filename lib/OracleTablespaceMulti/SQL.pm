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

	-------------------------------------------------------------------------------
	-- TABLESPACES AUTOEXTENSIBLE NO
	-------------------------------------------------------------------------------

	-- Ermittlung der Grösse von Tablespaces ohne Autoextend:

	select 
			T1.TABLESPACE_NAME, 
			datafiles, 
			totalbytes, 
			currbytes,
			freebytes,
			round(nvl((currbytes - freebytes) / totalbytes,0)*100,2) "PCT_USED",  
			round(100-nvl((currbytes - freebytes) / totalbytes,0)*100,2) "PCT_FREE",      
			\'NO\' as AUTOEXTENSIBLE,
			\'NO\' as TEMP
	FROM  
	(select count(1) datafiles, SUM(bytes) totalbytes, tablespace_name from dba_data_files WHERE AUTOEXTENSIBLE=\'NO\' GROUP BY tablespace_name) T1, -- OK
	(select tablespace_name, SUM(bytes) currbytes FROM dba_data_files  GROUP BY tablespace_name) T2, -- OK
	(SELECT tablespace_name, SUM(bytes) freebytes FROM dba_free_space GROUP BY tablespace_name) TF1 -- OK
	WHERE 
	T1.tablespace_name = T2.tablespace_name
	AND
	T1.tablespace_name = TF1.tablespace_name

	union all -- UNION

	-------------------------------------------------------------------------------
	-- TABLESPACES AUTOEXTENSIBLE YES
	-------------------------------------------------------------------------------

	-- Ermittlung der Grösse von Tablespaces mit Autoextend:
	select 
			T3.TABLESPACE_NAME, 
			datafiles, 
			totalbytes, 
			currbytes,
			freebytes,
			round(nvl((currbytes - freebytes) / totalbytes,0)*100,2) "PCT_USED",  
			round(100-nvl((currbytes - freebytes) / totalbytes,0)*100,2) "PCT_FREE",      
			\'YES\' as AUTOEXTENSIBLE,
			\'NO\' as TEMP
	FROM
	(select count(1) datafiles, SUM(maxbytes) totalbytes, tablespace_name from dba_data_files WHERE AUTOEXTENSIBLE=\'YES\' GROUP BY tablespace_name) T3,  -- OK
	(select tablespace_name, SUM(bytes) currbytes FROM dba_data_files GROUP BY tablespace_name) T4,  -- OK
	(SELECT tablespace_name, SUM(bytes) freebytes FROM dba_free_space GROUP BY tablespace_name) TF2  -- OK
	WHERE 
	T3.tablespace_name = T4.tablespace_name
	AND
	T3.tablespace_name = TF2.tablespace_name

	-------------------------------------------------------------------------------
	-- TEMP NO
	-------------------------------------------------------------------------------

	union all -- UNION

	-- Ermittlung der Grösse von TEMP Tablespaces ohne Autoextend:
	Select 
			T5.TABLESPACE_NAME, 
			T5.datafiles, 
			totalbytes,
			currbytes,
			freebytes,
			round(nvl((currbytes - freebytes) / totalbytes,0)*100,2) "PCT_USED",  
			round(100-nvl((currbytes - freebytes) / totalbytes,0)*100,2) "PCT_FREE",              
			\'NO\' as AUTOEXTENSIBLE,
			\'YES\' as TEMP
	FROM
	(select count(1) datafiles, SUM(bytes) totalbytes, tablespace_name from dba_temp_files WHERE AUTOEXTENSIBLE=\'NO\' GROUP BY tablespace_name) T5, -- OK 
	(select count(1) datafiles, SUM(bytes) currbytes, tablespace_name from dba_temp_files GROUP BY tablespace_name) T6,
	(select TABLESPACE_NAME, FREE_SPACE as freebytes from dba_temp_free_space) TF3
	WHERE 
	T5.tablespace_name = T6.tablespace_name
	AND
	T5.tablespace_name = TF3.tablespace_name

	-------------------------------------------------------------------------------
	-- TEMP YES
	-------------------------------------------------------------------------------

	union all -- UNION

	-- Ermittlung der Grösse von TEMP Tablespaces mit Autoextend:
	Select 
			T7.TABLESPACE_NAME, 
			T7.datafiles, 
			totalbytes,
			currbytes,
			freebytes,
			round(nvl((currbytes - freebytes) / totalbytes,0)*100,2) "PCT_USED",  
			round(100-nvl((currbytes - freebytes) / totalbytes,0)*100,2) "PCT_FREE",   
			\'YES\' as AUTOEXTENSIBLE,
			\'YES\' as TEMP
	FROM
	(select count(1) datafiles, SUM(maxbytes) totalbytes,  tablespace_name from dba_temp_files WHERE AUTOEXTENSIBLE=\'YES\' GROUP BY tablespace_name) T7, -- OK
	(select count(1) datafiles, SUM(bytes) currbytes, tablespace_name from dba_temp_files GROUP BY tablespace_name) T8,
	(select TABLESPACE_NAME, FREE_SPACE as freebytes from dba_temp_free_space) TF4
	WHERE 
	T7.tablespace_name = T8.tablespace_name
	AND
	T7.tablespace_name = TF4.tablespace_name
	';


	my $dbh = DBI->connect("dbi:Oracle:host=$Options{'hostname'};sid=$Options{'sid'}", $Options{'username'}, $Options{'password'})

	or die( $DBI::errstr . "\n");

	my $sth = $dbh->prepare($sql);
       $sth->execute;
        
	   
	 use Data::Dumper;


	my $TABLESPACE_NAME;
	while ( my $row = $sth->fetchrow_hashref ) {
		
		# '' => NULL
		map { $row->{$_} = "NULL" unless defined ($row->{$_}); } keys(%{$row});


		if (defined ( $Options{'TS'}{$row->{'TABLESPACE_NAME'}} ) ) {

		    if (defined ( $Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'TOTALBYTES'} ) ) {
			  $Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'TOTALBYTES'}   += $row->{'TOTALBYTES'};
		    }

		    if (defined ( $Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'DATAFILES'} ) ) {
			  $Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'DATAFILES'}   += $row->{'DATAFILES'};
		    }

		    if (defined ( $Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'AUTOEXTENSIBLE'} ) ) {
			  $Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'AUTOEXTENSIBLE'}  = 'MIXED';
			}

			$Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'PCT_USED'} = ( $Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'CURRBYTES'} - $Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'FREEBYTES'} ) / $Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'TOTALBYTES'} * 100;
			$Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'PCT_USED'} = sprintf ("%.2f", $Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'PCT_USED'});
			$Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'PCT_FREE'} = 100 - $Options{'TS'}{$row->{'TABLESPACE_NAME'}}{'PCT_USED'};

		} else {
		     $Options{'TS'}{$row->{'TABLESPACE_NAME'}} = $row;
		}
       
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


