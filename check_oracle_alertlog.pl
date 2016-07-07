#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: check_oracle_alertlog.pl
#
#        USAGE: ./check_oracle_alertlog.pl  
#
#  DESCRIPTION: Checks the oracle alert logs
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
my $module = 'Data::Dumper';
load $module;

#===============================================================================
# OPTIONS
#===============================================================================

my %Options = ();
$Options{'print-ok'} = "yes";

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
            'minutes:i',      #
            'hours:i',      #
            'days:i',      #
            'ok:s',      #
            'warning:s',      #
            'critical:s',      #
            'username:s',      #
            'password:s',      #
);

#===============================================================================
# PARSE OPTIONS
#===============================================================================

my $ParseOptions = 'OracleAlertLog::ParseOptions';
load $ParseOptions;
$ParseOptions = $ParseOptions->new();
%Options = $ParseOptions->parse(\%Options);


#===============================================================================
# SQL
#===============================================================================

my $SQL = 'OracleAlertLog::SQL';
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


my @msg;

my @ORA_CRITICAL;
if (defined($Options{'critical'})) {
   (@ORA_CRITICAL) = split(/\,/,$Options{'critical'});
}

my @ORA_WARNING;
if (defined($Options{'warning'})) {
   (@ORA_WARNING) = split(/\,/,$Options{'warning'});
}

my @ORA_OK;
if (defined($Options{'ok'})) {
   (@ORA_OK) = split(/\,/,$Options{'ok'});
}

my @ORA_OK_STATUS;
my @ORA_CRITICAL_STATUS;
my @ORA_WARNING_STATUS;
my $c1 =0;
my $c2 =0;

if (defined($Options{'ALERTLOG'})){
	foreach my $record_id (keys %{ $Options{'ALERTLOG'} } ) {
        
		# dimschalter
		$c1 = 1;
		$c2 = 0;

		# OK 
		for my $ora (@ORA_OK) {

		   if ( grep ( /$ora/,$Options{'ALERTLOG'}{$record_id}{'MESSAGE_TEXT'})) {
			          push(@ORA_OK_STATUS,$NagiosStatus{0}); 
					  $Options{'nagios-msg'} = $NagiosStatus{0};
                      ++$c2;
			   }
		}

		# WARNINGS
		for my $ora (@ORA_WARNING) {
		   if ( grep ( /$ora/,$Options{'ALERTLOG'}{$record_id}{'MESSAGE_TEXT'})) {
			          push(@ORA_WARNING_STATUS,$NagiosStatus{1}); 
					  $Options{'nagios-msg'} =  $NagiosStatus{1};
                      ++$c2;
			   }
		}

		# CRITICAL
		for my $ora (@ORA_CRITICAL) {
		   if ( grep ( /$ora/,$Options{'ALERTLOG'}{$record_id}{'MESSAGE_TEXT'})) {
			          push(@ORA_CRITICAL_STATUS,$NagiosStatus{2}); 
					  $Options{'nagios-msg'} =  $NagiosStatus{2};
                      ++$c2;
			   }
		}

		# DEFAULT
		if ( $c1 > $c2 ) {
			# defaults
			push(@ORA_CRITICAL_STATUS,$NagiosStatus{2}); 
			$Options{'nagios-msg'} = $NagiosStatus{2};
		}	

		next if ( $Options{'nagios-msg'} eq 'OK' and $Options{'print-ok'} ne 'yes' );
		
        # fill msg array
	    push (@msg,sprintf "%s\n%s\n%s\n%s\n",
			       "$Options{'nagios-msg'}" , 
				   "RECORD_ID => $Options{'ALERTLOG'}{$record_id}{'RECORD_ID'}",
				   "TIMESTAMP => $Options{'ALERTLOG'}{$record_id}{'ORIGINATING_TIMESTAMP'}",
				   "MESSAGE_TEXT => \n$Options{'ALERTLOG'}{$record_id}{'MESSAGE_TEXT'}"
		);

	}
}

if (@ORA_CRITICAL_STATUS) {
       $Options{'nagios-status'} = $NagiosStatus{'CRITICAL'};
       $Options{'nagios-msg'} = $NagiosStatus{2};
}
elsif (@ORA_WARNING_STATUS) {
       $Options{'nagios-status'} = $NagiosStatus{'WARNING'};
       $Options{'nagios-msg'} = $NagiosStatus{1};
} else {
       $Options{'nagios-status'} = $NagiosStatus{'OK'};
       $Options{'nagios-msg'} = $NagiosStatus{0};
}

print $Options{'nagios-msg'} . ' - W[' . scalar(@ORA_WARNING_STATUS) . ']:C[' .  scalar(@ORA_CRITICAL_STATUS) . ']' . "\n";
print @msg;
exit($Options{'nagios-status'});


__END__

=head1 NAME

check_oracle_alertlog.pl 

=head1 SYNOPSIS

./check_oracle_alertlog.pl 

=head1 DESCRIPTION

This description does not exist yet, it
was made for the sole purpose of demonstration.

=head1 LICENSE

This is released under the GPL3.

=head1 AUTHOR

Denis Immoos - <denisimmoos@gmail.com>, Senior Linux System Administrator (LPIC3)





