package SBEAMS::Connection::DBConnector;

###############################################################################
# Program     : SBEAMS::Connection::DBConnector
# Author      : Eric Deutsch <edeutsch@systemsbiology.org>
# $Id$
#
# Description : This is part of the SBEAMS::Connection module which handles
#               connections to the database.
#
###############################################################################


use strict;
use vars qw($DB_SERVER $DB_DATABASE $DB_USER $DB_PASS $DB_DRIVER
            $DB_DSN $dbh $dbh2);
use DBI;
use SBEAMS::Connection::Settings;


###############################################################################
# DBI Connection Variables
###############################################################################
if ( $DBVERSION eq "Dev Branch 2" ) {
  $DB_SERVER   = 'tj-db2ks-01';
  $DB_DATABASE = 'sbeams3';
  $DB_USER     = 'sbeams';
  $DB_PASS     = 'SB444';
  $DB_DRIVER   = "DBI:Sybase:server=$DB_SERVER;database=$DB_DATABASE";
} elsif ( $DBVERSION eq "Dev Branch 1" ) {
  $DB_SERVER   = 'tj-db2ks-01';
  $DB_DATABASE = 'sbeams3';
  $DB_USER     = 'sbeams';
  $DB_PASS     = 'SB444';
  $DB_DRIVER   = "DBI:Sybase:server=$DB_SERVER;database=$DB_DATABASE";
} else {
  $DB_SERVER   = 'mssql';
  $DB_DATABASE = 'sbeams';
  $DB_USER     = 'sbeams';
  $DB_PASS     = 'SB444';
  $DB_DRIVER   = "DBI:Sybase:server=$DB_SERVER;database=$DB_DATABASE";
}

#$DB_DSN      = 'SBEAMS';
#$DB_DATABASE = 'sbdb';
#$DB_USER     = 'DataLoader';
#$DB_PASS     = 'DL444';
#$DB_DRIVER   = "DBI:ODBC:$DB_DSN"; # Set to your server


###############################################################################
# Global variables
###############################################################################



###############################################################################
# Constructor
###############################################################################
sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    return($self);
}


###############################################################################
# db Connect
#
# Perform the actual database connection open call via DBI.  This should
# be database independent, but hasn't been tested with several databases.
# Some databases may not support the "USE databasename" syntax.
# This should never be called except by getDBHandle().
###############################################################################
sub dbConnect {
    my $self = shift;
    my $dbh = DBI->connect("$DB_DRIVER", "$DB_USER", "$DB_PASS")
      or die "$DBI::errstr";
#    $dbh->do("use $DB_DATABASE") if $DB_DATABASE;
    return $dbh;
}


###############################################################################
# get DB Handle
#
# Returns the current database connection handle to be used by any query.
# If the database handle doesn't yet exist, dbConnect() is called to create
# one.
###############################################################################
sub getDBHandle {
    my $self = shift;

    $dbh = dbConnect() unless defined($dbh);

    return $dbh;
}


###############################################################################
# get DB Server
#
# Return the servername of the database
###############################################################################
sub getDBServer {
    return $DB_SERVER;
}


###############################################################################
# get DB Driver
#
# Return the driver name (DSN string) of the database connection.
###############################################################################
sub getDBDriver {
    return $DB_DRIVER;
}


###############################################################################
# get DB Database
#
# Return the database name of the connection.
###############################################################################
sub getDBDatabase {
    return $DB_DATABASE;
}


###############################################################################
# get DB User
#
# Return the username used to open the connection to the database.
###############################################################################
sub getDBUser {
    return $DB_USER;
}




###############################################################################

1;

__END__
###############################################################################
###############################################################################
###############################################################################

=head1 NAME

SBEAMS::Connection::DBConnector - Perl extension for providing a common database connection

=head1 SYNOPSIS

  Used as part of this system

    use SBEAMS::Connection;
    $adb = new SBEAMS::Connection;

    $dbh = $adb->getDBHandle();

=head1 DESCRIPTION

    This module is inherited by the SBEAMS::Connection module, 
    although it can be used on its own. Its main function
    is to provide a single database connection to be used 
    by all programs included in this application.

=head1 METHODS

=item B<getDBHandle()>

    Returns the current database handle (opening a connection if one does
    not yet exist, connected using the variables set in the DBConnector.pm
    file. 

=head1 AUTHOR

Eric Deutsch <edeutsch@systemsbiology.org>

=head1 SEE ALSO

perl(1).

=cut
