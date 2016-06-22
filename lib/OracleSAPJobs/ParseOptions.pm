package OracleSAPJobs::ParseOptions;

#===============================================================================
#
#         FILE: ParseOptions.pm
#      PACKAGE: OracleSAPJobs::ParseOptions
#
#  DESCRIPTION: ParseOptions for OracleSAPJobs
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
	# hostname
	#
	&error($caller,'$Options{hostname} must be defined') if not ( $Options{'H'} or $Options{'hostname'} ); 
	if ($Options{'H'}) { $Options{'hostname'} = $Options{'H'} };
	if ($Options{'hostname'}) { $Options{'H'} = $Options{'hostname'} };
	&verbose($caller,'$Options{hostname} = ' . $Options{'hostname'}  ) if ( $Options{'v'} or $Options{'verbose'} ); 

    # 
	# sid
	#
	&error($caller,'$Options{sid} must be defined') if not ( $Options{'S'} or $Options{'sid'} ); 
	if ($Options{'S'}) { $Options{'sid'} = $Options{'S'} };
	if ($Options{'sid'}) { $Options{'S'} = $Options{'sid'} };
	&verbose($caller,'$Options{sid} = ' . $Options{'sid'}  ) if ( $Options{'v'} or $Options{'verbose'} ); 

	#
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
	# warning minutes
	#
	&error($caller,'$Options{warning} must be defined') if not ( $Options{'W'} or $Options{'warning'} ); 
	if ($Options{'W'}) { $Options{'warning'} = $Options{'W'} };
	if ($Options{'warning'}) { $Options{'W'} = $Options{'warning'} };
	&verbose($caller,'$Options{warning} = ' . $Options{'warning'}  ) if ( $Options{'v'} or $Options{'verbose'} ); 
	# minutes 
	$Options{warning} = $Options{warning} * 60;
	$Options{W} = $Options{W} * 60;



    # 
	# critical minutes
	#
	&error($caller,'$Options{critical} must be defined') if not ( $Options{'C'} or $Options{'critical'} ); 
	if ($Options{'C'}) { $Options{'critical'} = $Options{'C'} };
	if ($Options{'critical'}) { $Options{'C'} = $Options{'critical'} };
	&verbose($caller,'$Options{critical} = ' . $Options{'critical'}  ) if ( $Options{'v'} or $Options{'verbose'} ); 
	
	# minutes 
	$Options{critical} = $Options{critical} * 60;
	$Options{C} = $Options{C} * 60;

	# gt
	&error($caller,'$Options{critical} must be greater than $Options{warning}') if ( $Options{'warning'} >= $Options{'critical'} );

    # 
	# funct
	#
	&error($caller,'$Options{funct} must be defined') if not ( $Options{'F'} or $Options{'funct'} ); 
	if ($Options{'F'}) { $Options{'funct'} = $Options{'F'} };
	if ($Options{'funct'}) { $Options{'F'} = $Options{'funct'} };
	&verbose($caller,'$Options{funct} = ' . $Options{'funct'}  ) if ( $Options{'v'} or $Options{'verbose'} ); 

	

	return %Options;
}

1;

__END__

=head1 NAME

OracleSAPJobs::ParseOptions - ParseOptions for OracleSAPJobs 

=head1 SYNOPSIS

use OracleSAPJobs::ParseOptions;

my $object = OracleSAPJobs::ParseOptions->new();

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


