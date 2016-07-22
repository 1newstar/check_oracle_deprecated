#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: check_oracle_rman_backups.pl
#
#        USAGE: ./check_oracle_rman_backups.pl  
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
my $module = 'Data::Dumper';
load $module;

#===============================================================================
# OPTIONS
#===============================================================================

my %Options = ();
$Options{'print-ok'} = "no";
$Options{'print-warning'} = "yes";
$Options{'print-critical'} = "yes";

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
    'I:i',  'interval:i',
    'T:s',  'input-type:s',
    'C:s',  'critical:s',
            'print-ok',      #
            'print-warning',      #
            'print-critical',      #
            'username:s',      #
            'password:s',      #
);

#===============================================================================
# PARSE OPTIONS
#===============================================================================

my $ParseOptions = 'OracleRmanBackup::ParseOptions';
load $ParseOptions;
$ParseOptions = $ParseOptions->new();
%Options = $ParseOptions->parse(\%Options);


#===============================================================================
# SQL
#===============================================================================

my $SQL = 'OracleRmanBackup::SQL';
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

	'COMPLETED'                => 'OK',
	'COMPLETED WITH WARNINGS'  => 'WARNING',
	'RUNNING WITH WARNINGS'    => 'WARNING',
	'RUNNING WITH ERRORS'      => 'CRITICAL',
	'COMPLETED WITH ERRORS'    => 'CRITICAL',
	'FAILED'                   => 'CRITICAL',
);



use Data::Dumper;

my @ok;
my @warning;
my @critical;

foreach my $rman (keys %{ $Options{'RMAN'} } ) {
	foreach my $rman_sub (keys %{ $Options{'RMAN'}{$rman} } ) {
	   if ( "$rman_sub" eq 'STATUS' ) {
	        $Options{'RMAN'}{$rman}{'NAGIOS_STATUS'} = $NagiosStatus{$Options{'RMAN'}{$rman}{$rman_sub}};

            push(@ok,$rman)        if ($Options{'RMAN'}{$rman}{'NAGIOS_STATUS'} eq 'OK'); 
			push(@warning,$rman)   if ($Options{'RMAN'}{$rman}{'NAGIOS_STATUS'} eq 'WARNING'); 
			push(@critical,$rman)  if ($Options{'RMAN'}{$rman}{'NAGIOS_STATUS'} eq 'CRITICAL'); 
	   }
	}
}



# defaults
$Options{'nagios-msg'} = $NagiosStatus{0};
$Options{'nagios-status'} = $NagiosStatus{'OK'};
$Options{'ok'} = @ok;
$Options{'warning'} = @warning;
$Options{'critical'} = @critical;

if (@warning) {
	$Options{'nagios-msg'} = $NagiosStatus{1};
	$Options{'nagios-status'} = $NagiosStatus{'WARNING'};
}

if (@critical) {
	$Options{'nagios-msg'} = $NagiosStatus{2};
	$Options{'nagios-status'} = $NagiosStatus{'CRITICAL'};
}

print "$Options{'nagios-msg'} - [O:$Options{'ok'}/W:$Options{'warning'}/C:$Options{'critical'}]" . "\n";

if ( $Options{'print-ok'} eq 'yes' or $Options{'print-ok'} eq 1 ) {

	foreach my $key (@ok) {
	  print "\n### OK ###\n";
      foreach my $sub_key (keys %{ $Options{'RMAN'}{$key} } ) { 
	      print "$sub_key => " .  $Options{'RMAN'}{$key}{$sub_key} . "\n";
	  }
	}

}	

if ( $Options{'print-warning'} eq 'yes' or $Options{'print-warning'} eq 1 ) {

	foreach my $key (@warning) {
	  print "\n### WARNING ###\n";
      foreach my $sub_key (keys %{ $Options{'RMAN'}{$key} } ) { 
	      print "$sub_key => " .  $Options{'RMAN'}{$key}{$sub_key} . "\n";
	  }
	}

}	

if ( $Options{'print-critical'} eq 'yes' or $Options{'print-critical'} eq 1 ) {

	foreach my $key (@critical) {
	  print "\n### CRITICAL ###\n";
      foreach my $sub_key (keys %{ $Options{'RMAN'}{$key} } ) { 
	      print "$sub_key => " .  $Options{'RMAN'}{$key}{$sub_key} . "\n";
	  }
	}

}	

exit($Options{'nagios-status'});


__END__

=head1 NAME

check_oracle_rman_backups.pl 

=head1 SYNOPSIS

./check_oracle_rman_backups.pl 

=head1 DESCRIPTION

This description does not exist yet, it
was made for the sole purpose of demonstration.

=head1 LICENSE

This is released under the GPL3.

=head1 AUTHOR

Denis Immoos - <denisimmoos@gmail.com>, Senior Linux System Administrator (LPIC3)





