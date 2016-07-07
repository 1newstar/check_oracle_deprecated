# check_oracle
Some random oracle check scripts

## All chek_oracle scripts share the following parameters:

- **--hostname**  [ip¦hostname]
- **-H** [ip¦hostname]
- **--sid** SID 
- **--authfile** - An authfile with username and a password below '\n'
- **-A** - An authfile with username and a password below '\n'
- **--username** - a username
- **--password** - a password
- **-v** - be verbous
- **-h** - help not yet written on all checks

Parameters can always be found in the main script under **Getopt::Long** :

**Example:**

<pre>
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
    'T:s',  'ts-statuses:s',
            'noperfdata',
            'excluded:s',
            'username:s',      #
            'password:s',      #
);
</pre>

There are at least two modules for each check:

**Example:**

<pre>
./lib/OracleStatus/ParseOptions.pm
./lib/OracleStatus/SQL.pm
</pre>

- **ParseOptions.pm** - Module wich handels the parameters, options.
- **SQL.pm** - SQL related stuff



### .check_oracle_status.pl

**Example:**

<pre>
# ./check_oracle_status.pl --hostname hostname --sid SID  --authfile ../auth.file
# ./check_oracle_status.pl --hostname hostname --sid SID  --username username --password password
</pre>

### ./check_oracle_tablespace_multi.pl

Check multiple Oracle tablespaces at once.

**Example:**

<pre>
# ./check_oracle_tablespace_multi.pl -H hostname --sid SID --ts-statuses DEFAULT:96:100  -A /etc/icinga2/auth/hostname.auth --excluded NULL
</pre>

- --ts-statuses DEFAULT:96:100 - For all found tablespaces the default is WARNING 96% and CRITICAL 100%
- --excluded NULL - No tablespace is excluded from the check.
- --excluded SYSAUX,USERS - These tablespaces are excluded
- --ts-statuses DEFAULT:96:100,SYSAUX:75:90 - SYSAUX will WARN at 75% and go CRITICAL on 90%


**Example Output:**

<pre>
OK       - C​[0]​:W​[0]
W  - Warning
C  - Critical
AE - Autoextensible
DF - Datafiles

OK       - SYSAUX 	     40.35% 	 W​[96%]​:C​[100%]​:AE​[NO]​:DF​[1] 
OK       - USERS 	      62.6% 	  W​[96%]​:C​[100%]​:AE​[NO]​:DF​[1] 
OK       - USERS_​IDX 	 63.4% 	  W​[96%]​:C​[100%]​:AE​[NO]​:DF​[1] 
OK       - SYSTEM 	     61.95% 	 W​[96%]​:C​[100%]​:AE​[NO]​:DF​[1] 
OK       - RBS 	        70.05% 	 W​[96%]​:C​[100%]​:AE​[NO]​:DF​[1] 
OK       - TOOLS 	        .25% 	 W​[96%]​:C​[100%]​:AE​[NO]​:DF​[1] 
OK       - USERS_​LOB 	84.​71% 	 W​[96%]​:C​[100%]​:AE​[NO]​:DF​[2]
</pre>



### ./check_oracle_sap_jobs.pl 

Check if a SAP-job was running and when it was last run.
Warns if there is a failure or if the job was not run for x-minutes.

- **-W** - Warning in Minutes - If a job is not run for x-minutes warn.
- **-C** - Critical in Minutes

**Example:**

<pre>
./check_oracle_sap_jobs.pl --hostname hostname --sid SID --authfile ../auth.file -W 4000 -C 5760 -F vst
</pre>

Maybe this helps to clarify:

<pre>
 my $sql = "select * FROM ( select FUNCT,ENDE,RC from $Options{'schema'} where FUNCT=\'$Options{'funct'}\' order by ENDE desc ) WHERE rownum = 1";
</pre>

:) - I really think none but me has use for it ...




