#!/usr/bin/env perl 
#===============================================================================
#

#
#        USAGE: ./check_oracle_tablespace_multi.pl  
#
#  DESCRIPTION: Checks multiple oracle tablespaces
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Denis Immoos (<denisimmoos@gmail.com>)
#    AUTHORREF: Senior Linux System Administrator (LPIC3)
#      VERSION: 1.0
#      CREATED: 01/20/2016 09:26:28 AM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

#use lib '/usr/lib64/nagios/plugins/check_oracle/lib';
use lib '/home/monitor/check_oracle/lib';


#===============================================================================
# MODULES
#===============================================================================

use Module::Load;
#my $module = 'Data::Dumper';
#load $module;

#===============================================================================
# OPTIONS
#===============================================================================

my %Options = ();
$Options{'print-options'} = "no";

#===============================================================================
# SYGNALS - to syslog
#===============================================================================

# You can get all SIGNALS by:
# perl -e 'foreach (keys %SIG) { print "$_\n" }'
# $SIG{'INT'} = 'DEFAULT';
# $SIG{'INT'} = 'IGNORE';

sub INT_handler {
    my($signal) = @_;
    chomp $signal;
    use Sys::Syslog;
    my $msg = "INT: int($signal)\n";
    print $msg;
    syslog('info',$msg);
    exit(0);
}
$SIG{INT} = 'INT_handler';

sub DIE_handler {
    my($signal) = @_;
    chomp $signal;
    use Sys::Syslog;
    my $msg = "DIE: die($signal)\n";
    print $msg;
    syslog('info',$msg);
}
$SIG{__DIE__} = 'DIE_handler';

sub WARN_handler {
    my($signal) = @_;
    chomp $signal;
    use Sys::Syslog;
    my $msg = "WARN: warn($signal)\n";
    print $msg;
    syslog('info',$msg);
}
$SIG{__WARN__} = 'WARN_handler';

#===============================================================================
# Getopt::Long;
#===============================================================================

use Getopt::Long;
Getopt::Long::Configure ("bundling");
GetOptions( \%Options,
    'v',    'verbose',
    'h',    'help',
    'H:s',  'hostname:s',
    'A:s',  'authfile:s',
    'S:s',  'sid:s',
    'T:s',  'ts-statuses:s',
            'excluded:s',
            'noperfdata',
			'username:s',
			'password:s',
);

#===============================================================================
# PARSE OPTIONS
#===============================================================================

my $ParseOptions = 'OracleTablespaceMulti::ParseOptions';
load $ParseOptions;
$ParseOptions = $ParseOptions->new();
%Options = $ParseOptions->parse(\%Options);


#===============================================================================
# SQL
#===============================================================================

my $SQL = 'OracleTablespaceMulti::SQL';
load $SQL;
$SQL = $SQL->new();
%Options = $SQL->sql(\%Options);


#===============================================================================
# MAIN
#===============================================================================

#===============================================================================
# Nagios
#===============================================================================

my %NagiosStatus = (
    OK       => 0,
    WARNING  => 1,
    CRITICAL => 2,
    UNKNOWN  => 3,

    0       => 'OK',
    1       => 'WARNING',
    2       => 'CRITICAL',
    3       => 'UNKNOWN',
);

# array for statuses
# warnings + critical
my $warning;
my $critical;
my @critical;
my @warning;
my @msg;
my @perfdata;
my $perfdata;

foreach my $tablespace (keys %{ $Options{'TS'} } ) {

	# defaults
	$Options{'nagios-msg'} = $NagiosStatus{0};
	$Options{'nagios-status'} = $NagiosStatus{'OK'};

	# "TABLESPACE_NAME", "PCT_USED", "ALLOCATED", "USED", "FREE", "DATAFILES"
	next if (
	     $Options{'TS'}{$tablespace}{'PCT_USED'} eq 'NULL'
	     or
	     $Options{'TS'}{$tablespace}{'ALLOCATED'} eq 'NULL'
	     or
	     $Options{'TS'}{$tablespace}{'USED'} eq 'NULL'
	     or
	     $Options{'TS'}{$tablespace}{'FREE'} eq 'NULL'
	     or
	     $Options{'TS'}{$tablespace}{'DATAFILES'} eq 'NULL'
		 or 
		 grep(/^$tablespace$/, @{ $Options{'excluded'} } )
	); 



    if ( 
		defined ( $Options{'tablespaces'}{$tablespace}{'warning'}) 
			and 
		defined ( $Options{'tablespaces'}{$tablespace}{'critical'}) 
	) {
		$warning = $Options{'tablespaces'}{$tablespace}{'warning'};
		$critical = $Options{'tablespaces'}{$tablespace}{'critical'};
	} else {
	    $warning = $Options{'tablespaces'}{'DEFAULT'}{'warning'};
	    $critical = $Options{'tablespaces'}{'DEFAULT'}{'critical'};
	}	

    # percentage

	if ( $Options{'TS'}{$tablespace}{'PCT_USED'} >= $critical) {
	   $Options{'nagios-msg'} = $NagiosStatus{2};
	   $Options{'nagios-status'} = $NagiosStatus{'CRITICAL'};
	   push(@critical,$Options{'nagios-status'});
	}
	elsif ( $Options{'TS'}{$tablespace}{'PCT_USED'} >= $warning) {
	   $Options{'nagios-msg'} = $NagiosStatus{1};
	   $Options{'nagios-status'} = $NagiosStatus{'WARNING'};
	   push(@warning,$Options{'nagios-status'});
	}


	chomp($warning);
	chomp($critical);

	# fill msg array
	push (@msg,sprintf "%-8s - %s \t %8s%% \t %s \n","$Options{'nagios-msg'}" , "$tablespace","$Options{'TS'}{$tablespace}{'PCT_USED'}","W[$warning\%]:C[$critical\%]:AE[$Options{'TS'}{$tablespace}{'AUTOEXTENSIBLE'}]:DF[$Options{'TS'}{$tablespace}{'DATAFILES'}]");
    push (@perfdata,"$tablespace=$Options{'TS'}{$tablespace}{'PCT_USED'}\%;$warning;$critical;0;100");
	
}

if (@critical) {
	   $Options{'nagios-msg'} = $NagiosStatus{2};
	   $Options{'nagios-status'} = $NagiosStatus{'CRITICAL'};
} 
elsif (@warning) {
	   $Options{'nagios-msg'} = $NagiosStatus{1};
	   $Options{'nagios-status'} = $NagiosStatus{'WARNING'};
} 

# missuse the variables for mathemagical things
$warning = @warning;
$critical = @critical;


# Performanc data
if (not defined($Options{'noperfdata'})) { 
	$perfdata = '| ' . join("\, ",@perfdata);
}

printf  "%-8s - %s \n", $Options{'nagios-msg'}, "C[$critical]:W[$warning] $perfdata";
print "\n";
print "W  - Warning\n";
print "C  - Critical\n";
print "AE - Autoextensible\n";
print "DF - Datafiles\n";
print "\n";
print @msg;
print "\n";

if ($Options{'print-options'} eq "yes" ) {
    print 'Options: ' ."\n\n";
	foreach my $option (keys(%Options)) {
	   print "$option => $Options{$option}" . "\n";
	}
}



exit($Options{'nagios-status'});


__END__

=head1 NAME

check_oracle_tablespace_multi.pl - Checks multiple oracle tablespaces

=head1 SYNOPSIS

./check_oracle_tablespace_multi.pl 

=head1 DESCRIPTION

This description does not exist yet, it
was made for the sole purpose of demonstration.

=head1 LICENSE

This is released under the GPL3.

=head1 AUTHOR

Denis Immoos - <denisimmoos@gmail.com>, Senior Linux System Administrator (LPIC3)





