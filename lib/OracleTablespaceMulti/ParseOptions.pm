package OracleTablespaceMulti::ParseOptions;

#===============================================================================
#
#         FILE: ParseOptions.pm
#      PACKAGE: OracleTablespaceMulti::ParseOptions
#
#  DESCRIPTION: ParseOptions for OracleTablespaceMulti
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Denis Immoos (<denisimmoos@gmail.com>)
#    AUTHORREF: Senior Linux System Administrator (LPIC3)
#      VERSION: 1.0
#      CREATED: 11/22/2015 03:11:47 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

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


sub parse {
	my $self = shift;
	my $ref_Options = shift;
	my %Options = %{ $ref_Options };
	my $caller = (caller(0))[3];


	foreach my $opt (keys(%Options)) {
		&error($caller,'$Options{' . $opt . '} not defined') if not ($Options{$opt}); 
	    &verbose($caller,'$Options{' . $opt . '} defined') if ( $Options{'v'} or $Options{'verbose'} ); 
	}

	#
	# critical,ok,warning,unknown
	#
	if ($Options{'ts-statuses'}) { $Options{'T'} = $Options{'ts-statuses'} };
	if ($Options{'T'}) { $Options{'ts-statuses'} = $Options{'T'} };

	&error($caller,'$Options{ts-statuses} must be defined') if not ( $Options{'T'} or $Options{'ts-statuses'} ); 
	&verbose($caller,'$Options{ts-statuses} = ' . $Options{'T'}  ) if ( $Options{'v'} or $Options{'verbose'} ); 

	my @ts_statuses  = split(/\,/,$Options{'ts-statuses'});
    my @ts_statuses_sub;


	# DEFAULT:80:90 -> DEFAULT 80 90
	foreach my $ts_status (@ts_statuses) {

      @ts_statuses_sub = split(/\:/,$ts_status);
	  my $tablespace = $ts_statuses_sub[0];
	  my $warning = $ts_statuses_sub[1];
	  my $critical = $ts_statuses_sub[2];

	  $Options{'tablespaces'}{$tablespace}{'warning'} = $warning;
	  &verbose($caller, '$Options{tablespaces}{' . $tablespace . '}{warning} = ' . $Options{'tablespaces'}{$tablespace}{'warning'} ) if ( $Options{'v'} or $Options{'verbose'} );

	  $Options{'tablespaces'}{$tablespace}{'critical'} = $critical;
	  &verbose($caller, '$Options{tablespaces}{' . $tablespace . '}{critical} = ' . $Options{'tablespaces'}{$tablespace}{'critical'} ) if ( $Options{'v'} or $Options{'verbose'} );

	  if ( $Options{'tablespaces'}{$tablespace}{'critical'} <= $Options{'tablespaces'}{$tablespace}{'warning'} ) {
	     &error($caller,'$Options{\'tablespaces\'}{' . $tablespace . '}{\'critical\'} <= $Options{\'tablespaces\'}{'  . $tablespace . '}{\'warning\'}');
	  }

    }

	if (not defined $Options{'tablespaces'}{'DEFAULT'} ) {
		&error($caller,'A DEFAULT tablespace statuses must be defined [Example: --statuses DEFAULT:80:98] ')
	}

    # 
	# hostname
	#
	if ($Options{'H'}) { $Options{'hostname'} = $Options{'H'} };
	if ($Options{'hostname'}) { $Options{'H'} = $Options{'hostname'} };
	&error($caller,'$Options{hostname} must be defined') if not ( $Options{'H'} or $Options{'hostname'} ); 
	&verbose($caller,'$Options{hostname} = ' . $Options{'hostname'}  ) if ( $Options{'v'} or $Options{'verbose'} ); 

	#
    # 
	# sid
	#
	if ($Options{'S'}) { $Options{'sid'} = $Options{'S'} };
	if ($Options{'sid'}) { $Options{'S'} = $Options{'sid'} };
	&error($caller,'$Options{sid} must be defined') if not ( $Options{'S'} or $Options{'sid'} ); 
	&verbose($caller,'$Options{sid} = ' . $Options{'sid'}  ) if ( $Options{'v'} or $Options{'verbose'} ); 


	# authfile
	#
	if ( not ( $Options{'username'} and  $Options{'password'} )) {
	
		&error($caller,'$Options{authfile} must be defined') if not ($Options{'authfile'} or $Options{'A'} ); 
	    if ($Options{'A'}) { $Options{'authfile'} = $Options{'A'} };
	    if ($Options{'authfile'}) { $Options{'A'} = $Options{'authfile'} };
		&error($caller,'$Options{authfile} not a file') if not ( -f $Options{'authfile'} ); 
		&error($caller,'$Options{authfile} cannot be defined together with --username') if ( $Options{'username'} ); 
		&error($caller,'$Options{authfile} cannot be defined together with --password') if ( $Options{'password'} ); 
		&verbose($caller,'$Options{authfile} = ' . $Options{'authfile'}) if ( $Options{'v'} or $Options{'verbose'} ); 

		open(AUTHFILE,$Options{'authfile'}) or &error($caller,'open(' . $Options{authfile} .')');
		my @authfile;
		while (my $row = <AUTHFILE>) {
				chomp $row;
				push(@authfile,$row);
		}
		$Options{'username'} = $authfile[0];
		$Options{'password'} = $authfile[1];

		&error($caller,'$Options{authfile} format error') if ( scalar(@authfile) != 2 ); 
		close(AUTHFILE) or &error($caller,'close(' . $Options{authfile} .')');
	}


	#
	# username
	#
	&error($caller,'$Options{username} must be defined') if not ($Options{'username'} ); 
	&verbose($caller,'$Options{username} = ' . $Options{'username'}) if ( $Options{'v'} or $Options{'verbose'} ); 

	#
	# password
	#
	&error($caller,'$Options{password} must be defined') if not ($Options{'password'} ); 
	&verbose($caller,'$Options{password} = ' . $Options{'password'}) if ( $Options{'v'} or $Options{'verbose'} ); 



	#
	# excluded
	#
	if ($Options{'excluded'}) {
		my @excluded = split(/\,/,$Options{'excluded'});
		$Options{'excluded'} = \@excluded;
	    &verbose($caller,'$Options{excluded} = ' . "@{ $Options{'excluded'} }" ) if ( $Options{'v'} or $Options{'verbose'} ); 
	}

	return %Options;
}

1;

__END__

=head1 NAME

OracleTablespaceMulti::ParseOptions - ParseOptions for OracleTablespaceMulti 

=head1 SYNOPSIS

use OracleTablespaceMulti::ParseOptions;

my $object = OracleTablespaceMulti::ParseOptions->new();

my %HASH = $object->parse(\%HASH);

=head1 DESCRIPTION

This description does not exist yet, it
was made for the sole purpose of demonstration.

=head1 LICENSE

This is released under the GPL3.

=head1 AUTHOR

Denis Immoos - <denisimmoos@gmail.com>,
Senior Linux System Administrator (LPIC3)

=cut


