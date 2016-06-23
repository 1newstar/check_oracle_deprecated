# check_oracle
Some random oracle check scripts

## All chek_oracle scripts share the following parameters:

- --hostname  [ip¦hostname]
- --sid SID 
- --authfile - An authfile with username and a password below '\n'
- --username - a username
- --password - a password
- -v - be verbous
- -h - help not yet written on all checks

 ### .check_oracle_status.pl --hostname 

*Example:*

./check_oracle_status.pl --hostname hostname --sid SID  --authfile ../auth.file
./check_oracle_status.pl --hostname hostname --sid SID  --username username --password password

