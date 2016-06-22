package OracleSAPJobs::SQL;

#===============================================================================
#
#         FILE: SQL.pm
#      PACKAGE: SQL
#
#  DESCRIPTION: SQL OracleSAPJobs
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


	# letzte zeile 
	my $sql = "select * FROM ( select FUNCT,ENDE,RC from $Options{'schema'} where FUNCT=\'$Options{'funct'}\' order by ENDE desc ) WHERE rownum = 1";
	
	#die;

    my $dbh = DBI->connect("dbi:Oracle:host=$Options{'hostname'};sid=$Options{'sid'}", $Options{'username'}, $Options{'password'} )
    or die( $DBI::errstr . "\n");

    my $sth = $dbh->prepare($sql);
       $sth->execute;
		use Data::Dumper;
	while ( my $row = $sth->fetchrow_hashref ) {

		map { $row->{$_} = "NULL" unless defined ($row->{$_}); } keys(%{$row});
		# its only one ;) 
		$Options{'ORACLE_SAP_JOB'} = $row;
	}
		
	return  %Options;
}

1;

__END__

=head1 NAME

SQL - SQL OracleSAPJobs 

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


