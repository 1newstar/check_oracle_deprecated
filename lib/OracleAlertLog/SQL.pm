package OracleAlertLog::SQL;

#===============================================================================
#
#         FILE: SQL.pm
#      PACKAGE: SQL
#
#  DESCRIPTION: SQL OracleAlertLog
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


	# INSTALL
	#
	# SQL> grant select on v$diag_alert_ext to monitor;
	# select ORIGINATING_TIMESTAMP,message_text
	# from v$diag_alert_ext
	# where message_text like '%ORA-%'
	#	or upper(message_text) like '%ERROR%'
	#	order by originating_timestamp;



	my $sql = "SELECT record_id, to_char(originating_timestamp,'DD.MM.YYYY HH24:MI:SS') AS originating_timestamp, message_text FROM v\$diag_alert_ext WHERE originating_timestamp >= SYSTIMESTAMP - INTERVAL '$Options{time}' $Options{time_unit} AND ( message_text LIKE '\%ORA-\%' or upper(message_text) like '%ERROR%')  order by originating_timestamp";


	#die;

    my $dbh = DBI->connect("dbi:Oracle:host=$Options{'hostname'};sid=$Options{'sid'}", $Options{'username'}, $Options{'password'} )
    or die( $DBI::errstr . "\n");

    my $sth = $dbh->prepare($sql);
       $sth->execute;
	# $VAR1 = {
	#           'MESSAGE_TEXT' => 'Errors in file /oracle/BTX/saptrace/diag/rdbms/btx/BTX/trace/BTX_m001_5685.trc:
	#           ORA-25153: Temporary Tablespace is Empty
	#           ',
	#           'TO_CHAR(ORIGINATING_TIMESTAMP,\'DD.MM.YYYYHH24:MI:SS\')' => '07.01.2016 01:53:19',
	#           'RECORD_ID' => '38048'
	#           };

	while ( my $row = $sth->fetchrow_hashref ) {
		map { $row->{$_} = "NULL" unless defined ($row->{$_}); } keys(%{$row});
		$Options{'ALERTLOG'}{$row->{'RECORD_ID'}} = $row;
	}
	return  %Options;
}



1;

__END__

=head1 NAME

SQL - SQL OracleAlertLog 

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


