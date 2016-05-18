#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: check_tablespace_multi.pl
#
#        USAGE: ./check_tablespace_multi.pl  
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

use lib '/usr/lib64/nagios/plugins/check_oracle/lib';

#===============================================================================
# MODULES
#===============================================================================

use Module::Load;
my $module = 'Data::Dumper';
load $module;

#===============================================================================
# OPTIONS
#===============================================================================

my %Options = ();
$Options{'print-options'} = "yes";

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
GetOptions(\%Options,
    'v',    'verbose',
    'h',    'help',
    'H:s',  'hostname:s',
    'A:s',  'authfile:s',
    'S:s',  'sid:s',
    'W:s',  'warning:s',
    'C:s',  'critical:s',
            'percent',
            'noperfdata',
            'username:s',      #
            'password:s',      #
);

#===============================================================================
# PARSE OPTIONS
#===============================================================================

my $ParseOptions = 'OracleOpenSessions::ParseOptions';
load $ParseOptions;
$ParseOptions = $ParseOptions->new();
%Options = $ParseOptions->parse(\%Options);


#===============================================================================
# SQL
#===============================================================================

my $SQL = 'OracleOpenSessions::SQL';
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


# defaults
$Options{'nagios-msg'} = $NagiosStatus{0};
$Options{'nagios-status'} = $NagiosStatus{'OK'};


if (defined($Options{'percent'})) {

    $Options{'percent'} = sprintf( "%.0f",$Options{'OPEN_SESSIONS'}/$Options{'MAX_SESSIONS'}*100);

	if ( $Options{'percent'} >= $Options{'critical'}) {
	   $Options{'nagios-msg'} = $NagiosStatus{2};
	   $Options{'nagios-status'} = $NagiosStatus{'CRITICAL'};
	}
	elsif ( $Options{'percent'} >= $Options{'warning'}) {
	   $Options{'nagios-msg'} = $NagiosStatus{1};
	   $Options{'nagios-status'} = $NagiosStatus{'WARNING'};
	}

} else {

	if ( $Options{'OPEN_SESSIONS'} >= $Options{'critical'}) {
	   $Options{'nagios-msg'} = $NagiosStatus{2};
	   $Options{'nagios-status'} = $NagiosStatus{'CRITICAL'};
	}
	elsif ( $Options{'OPEN_SESSIONS'} >= $Options{'warning'}) {
	   $Options{'nagios-msg'} = $NagiosStatus{1};
	   $Options{'nagios-status'} = $NagiosStatus{'WARNING'};
	}
}


my $perfdata;
if (not defined($Options{'noperfdata'}) and not defined($Options{'percent'}) ) { 
  $perfdata = '| ' . "OPEN_SESSIONS=$Options{'OPEN_SESSIONS'};$Options{'warning'};$Options{'critical'};0;$Options{'MAX_SESSIONS'}, MAX_SESSIONS=$Options{'MAX_SESSIONS'};$Options{'warning'};$Options{'critical'};0;$Options{'MAX_SESSIONS'}" 
}

if (not defined($Options{'noperfdata'}) and defined($Options{'percent'}) ) { 
  $perfdata = '| ' . "OPEN_SESSIONS=$Options{'OPEN_SESSIONS'};0;0, MAX_SESSIONS=$Options{'MAX_SESSIONS'};0;0, PCT_USED=$Options{'percent'}\%;$Options{'warning'};$Options{'critical'}" 
}


print "$Options{'nagios-msg'} $perfdata \n"; 

if ($Options{'print-options'} eq "yes" ) {
	    print 'Options: ' ."\n\n";
		foreach my $option (keys(%Options)) {
			
		  next if ( $option =~ /^[a-zA-Z]$/ );
		  next if ( $option eq 'password');
		  print "$option => $Options{$option}" . "\n";
		}
}

exit($Options{'nagios-status'});


__END__

=head1 NAME

check_tablespace_multi.pl - Checks multiple oracle tablespaces

=head1 SYNOPSIS

./check_tablespace_multi.pl 

=head1 DESCRIPTION

This description does not exist yet, it
was made for the sole purpose of demonstration.

=head1 LICENSE

This is released under the GPL3.

=head1 AUTHOR

Denis Immoos - <denisimmoos@gmail.com>, Senior Linux System Administrator (LPIC3)





