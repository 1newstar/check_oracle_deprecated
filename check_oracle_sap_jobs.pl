#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: check_oracle_sap_jobs.pl
#
#        USAGE: ./check_oracle_sap_jobs.pl  
#
#  DESCRIPTION: Checks SAP-jobs in oracle
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

#===============================================================================
# OPTIONS
#===============================================================================

my %Options = ();
$Options{'print-options'} = 'yes';
$Options{'schema'} = 'SAPSR3.SDBAH';
$Options{'timezone'} = 'Europe/Zurich';

# RC ohne führende 0*
$Options{'oks'} = [ 0 ];
$Options{'warnings'} = [ 1,2 ];
#-----> else is Critical

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
    'X:s',  'schema:s',
    'F:s',  'funct:s',
    'W:s',  'warning:i',
    'C:s',  'critical:i',
            'username:s',      #
            'password:s',      #
            'ok_array:s',      #
            'warn_array:s',      #
);

#===============================================================================
# PARSE OPTIONS
#===============================================================================

my $ParseOptions = 'OracleSAPJobs::ParseOptions';
load $ParseOptions;
$ParseOptions = $ParseOptions->new();
%Options = $ParseOptions->parse(\%Options);


#===============================================================================
# SQL
#===============================================================================

my $SQL = 'OracleSAPJobs::SQL';
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


# ueberschreiben ok_array
if ($Options{'ok_array'}) {
	my @ok_array = split(/\,/,$Options{'ok_array'});
	$Options{'oks'} = \@ok_array;
}

# ueberschreiben warn_array
if ($Options{'warn_array'}) {
	my @ok_array = split(/\,/,$Options{'warn_array'});
	$Options{'warnings'} = \@ok_array;
}


# RC führende 000* weg schneiden
$Options{'ORACLE_SAP_JOB'}{'RC'} =~ s/^0+//; 
#
# Stati
#
if ( not $Options{'ORACLE_SAP_JOB'}{'RC'} ) {
	$Options{'ORACLE_SAP_JOB'}{'JOB_STATUS'} = 'OK';
} elsif ( grep /^$Options{'ORACLE_SAP_JOB'}{'RC'}$/, @{ $Options{'oks'} }) {
	$Options{'ORACLE_SAP_JOB'}{'JOB_STATUS'} = 'OK';
}  elsif ( grep /^$Options{'ORACLE_SAP_JOB'}{'RC'}$/, @{ $Options{'warnings'} }) {
	$Options{'ORACLE_SAP_JOB'}{'JOB_STATUS'} = 'WARNING';
} else {
	$Options{'ORACLE_SAP_JOB'}{'JOB_STATUS'} = 'CRITICAL';
}


#===============================================================================
# DateTime
#===============================================================================
use DateTime;
my $dt_NOW = DateTime->now();
   $dt_NOW->set_time_zone( $Options{'timezone'} );

# datum aufsplitten
my @date_string = split(//,$Options{'ORACLE_SAP_JOB'}{'ENDE'});

# 20160620180102
my $dt_ENDE =  DateTime->new(
	year       => $date_string[0] . $date_string[1] . $date_string[2] . $date_string[3],
	month      => $date_string[4] . $date_string[5],
	day        => $date_string[6] . $date_string[7],
    hour       => $date_string[8] . $date_string[9],
    minute     => $date_string[10] . $date_string[11],
    second     => $date_string[12] . $date_string[13],
);
# set timezone
$dt_ENDE->set_time_zone( $Options{'timezone'} );

# absoluter Wert in Sekunden
my $dt_duration = $dt_NOW->subtract_datetime_absolute($dt_ENDE); 
# verstrichene Zeit in sekunden 
$Options{'ORACLE_SAP_JOB'}{'LAST_RUN_SECONDS'} = $dt_duration->seconds;

#$Options{'ORACLE_SAP_JOB'}{'STATUS'} 
#print Dumper(@date_string) . "\n";
#print Dumper($dt_NOW) . "\n";
#print Dumper($dt_ENDE) . "\n";
#print Dumper($dt_duration) . "\n";
# print Dumper($Options{'ORACLE_SAP_JOB'}) . "\n";

#
# defaults
#
$Options{'nagios-msg'} = $NagiosStatus{0};
$Options{'nagios-status'} = $NagiosStatus{'OK'};

if ( $Options{'ORACLE_SAP_JOB'}{'JOB_STATUS'} eq ( 'CRITICAL' or 'WARNING' )) {
  # Stati verwursteln		
  $Options{'nagios-msg'} = $Options{'ORACLE_SAP_JOB'}{'JOB_STATUS'};
  $Options{'nagios-status'} = $NagiosStatus{$Options{'ORACLE_SAP_JOB'}{'JOB_STATUS'}};
} 

if ( $Options{'ORACLE_SAP_JOB'}{'LAST_RUN_SECONDS'} >= $Options{'warning'} ) {

  $Options{'nagios-msg'} = 'WARNING - LAST_RUN_SECONDS => ' . $Options{'ORACLE_SAP_JOB'}{'LAST_RUN_SECONDS'};
  $Options{'nagios-status'} = $NagiosStatus{'WARNING'};

}

if ( $Options{'ORACLE_SAP_JOB'}{'LAST_RUN_SECONDS'} >= $Options{'critical'} ) {

  $Options{'nagios-msg'} = 'CRITICAL - LAST_RUN_SECONDS => ' . $Options{'ORACLE_SAP_JOB'}{'LAST_RUN_SECONDS'}; 
  $Options{'nagios-status'} = $NagiosStatus{'CRITICAL'};

}

print "$Options{'nagios-msg'}" . "\n";

if ($Options{'print-options'} eq "yes" ) {
	    print "\n";
	    print 'Options: ' ."\n\n";
		foreach my $option (keys(%Options)) {
			   next if ( $option =~ /password/ );
			   if ( $option =~ /(oks|warnings)/ ) {
				   print "$option => " . join(',',@{ $Options{$option} })  . "\n";
			   } elsif (  $option =~ /ORACLE_SAP_JOB/)   {
				   foreach my $oracle_sap_job (keys($Options{'ORACLE_SAP_JOB'})) {
					   print "ORACLE_SAP_JOB_${oracle_sap_job} => $Options{$option}{$oracle_sap_job}" . "\n";
				   }
			   } else  {
			      print "$option => $Options{$option}" . "\n";
			   }
		}
}
exit($Options{'nagios-status'});

__END__

=head1 NAME

check_oracle_sap_jobs.pl - Checks SAP-jobs in oracle

=head1 SYNOPSIS

./check_oracle_sap_jobs.pl 

=head1 DESCRIPTION

This description does not exist yet, it
was made for the sole purpose of demonstration.

=head1 LICENSE

This is released under the GPL3.

=head1 AUTHOR

Denis Immoos - <denisimmoos@gmail.com>, Senior Linux System Administrator (LPIC3)





