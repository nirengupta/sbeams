package SBEAMS::Connection::Authenticator;

###############################################################################
# Program     : SBEAMS::Connection::Authenticator
# Author      : Eric Deutsch <edeutsch@systemsbiology.org>
# $Id$
#
# Description : This is part of the SBEAMS::Connection module which handles
#               authentication to use the system.
#
###############################################################################


use strict;
use vars qw( $q $dbh $http_header @ISA @ERRORS $SECRET_KEY
             $current_contact_id $current_username
             $current_work_group_id $current_work_group_name 
             $current_project_id $current_project_name
             $current_user_context_id );

use CGI::Carp qw(fatalsToBrowser croak);
use CGI qw(-no_debug);
use DBI;
use SBEAMS::Connection::DBConnector;
use SBEAMS::Connection::Settings;
use SBEAMS::Connection::Tables;
use SBEAMS::Connection::TableInfo;
use Crypt::CBC;

$SECRET_KEY = 'PoIuYtReWq';

$q       = new CGI;


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
# Authenticate the user making the web request.
#
# This is run with every new page, first checking to see if the user already
# has a valid cookie indicating previous login.  If so, return the username,
# else the login process begins.  This is not really terribly secure.
# Login information is not encrypted during transmission unless an
# encryption layer is used.  The $SECRET_KEY should be rotated weekly
# or some such.
###############################################################################
sub Authenticate { 
    my $self = shift;
    my %params = @_;

    # Obtain the database handle $dbh, thereby option the DB connection
    $dbh = $self->getDBHandle();

    # If there's a DISABLED file in the main HTML directory, do not allow
    # entry past here
    if ( -e "$PHYSICAL_BASE_DIR/DISABLED" &&
         $ENV{REMOTE_ADDR} ne "10.0.230.11") {
      $self->printPageHeader();
      print "<H3>";
      open(INFILE,"$PHYSICAL_BASE_DIR/DISABLED");
      my $line;
      while ($line = <INFILE>) { print $line; }
      close(INFILE);
      $self->printPageFooter();
      exit;
    }

    # If the user is not logged in, make them log in
    unless ($current_username = $self->checkLoggedIn()) {
        $current_username = $self->processLogin();
    }

    # If we've obtained a valid user, get additional information about the user
    if ($current_username) {
        $current_contact_id = $self->getContact_id($current_username);
        $current_work_group_id = $self->getCurrent_work_group_id();
    }

    return $current_username;

} # end InterfaceEntry


###############################################################################
# Process Login
###############################################################################
sub processLogin {
    my $self = shift;

    my $username  = $q->param('username');
    my $password  = $q->param('password');
    $current_username = "";

    if ($q->param('login')) {
        if ($self->checkLogin($username, $password)) {
            $http_header = $self->createAuthHeader($username);
            $current_contact_id = $self->getContact_id($username);
            $current_username = $username;
        } else {
            $self->printPageHeader(minimal_header=>"YES");
            $self->printAuthErrors();
            $self->printPageFooter();
        }
    } else {
        $self->printPageHeader(minimal_header=>"YES");
        $self->printLoginForm();
        $self->printPageFooter();
    }

    return $current_username;

} # end processLogin


###############################################################################
# get HTTP Header
###############################################################################
sub get_http_header {
    my $self = shift;

    unless ($http_header) {
      $http_header = "Content-type: text/html\n\n";
    }

    return $http_header;

} # end get_http_header


###############################################################################
# checkLoggedIn
#
# Return the username if the user's cookie contains a valid username
###############################################################################
sub checkLoggedIn {
    my $self = shift;
    my $username = "";

    if ($main::q->cookie('SBEAMSName')){
        my $cipher = new Crypt::CBC($SECRET_KEY, 'IDEA');
        $username = $cipher->decrypt($main::q->cookie('SBEAMSName'));

        # Verify that the deciphered result is still an active username
        my ($result) = $self->selectOneColumn(
            "SELECT username
               FROM $TB_USER_LOGIN
              WHERE username = '$username'
                AND record_status != 'D'"
        );
        $username = "" if ($result ne $username);
    }

    return $username;
}


###############################################################################
# Return the contact_id of the user currently logged in
###############################################################################
sub getCurrent_contact_id {
    return $current_contact_id;
}


###############################################################################
# Return the username of the user currently logged in
###############################################################################
sub getCurrent_username {
    return $current_username;
}


###############################################################################
# Return the work_group_id of the user currently logged in
###############################################################################
sub getCurrent_work_group_id {
    my $self = shift;

    # If the current_work_group_id is already known, return it
    if ($current_work_group_id > 0) { return $current_work_group_id; }
    if ($current_contact_id < 1) { die "current_contact_id undefined!!"; }

    # Otherwise, see if it's in the user_context table
    ($current_work_group_id) = $self->selectOneColumn(
        "SELECT work_group_id
           FROM $TB_USER_CONTEXT
          WHERE contact_id = $current_contact_id
            AND record_status != 'D'
        ");
    if ($current_work_group_id > 0) { return $current_work_group_id; }

    # Not there, so let's just set it to the first group for this user
    ($current_work_group_id) = $self->selectOneColumn(
        "SELECT work_group_id
           FROM $TB_USER_WORK_GROUP
          WHERE contact_id = $current_contact_id
            AND record_status != 'D'
        ");
    if ($current_work_group_id > 0) {
        $self->executeSQL(
            "INSERT INTO $TB_USER_CONTEXT (contact_id,work_group_id,
              created_by_id,modified_by_id )
              VALUES ( $current_contact_id,$current_work_group_id,
              $current_contact_id,$current_contact_id )
            ");
        return $current_work_group_id;
    }

    # This user apparently does not belong to any groups, so set to Other
    $current_work_group_id = 2;

    return $current_work_group_id;
}


###############################################################################
# Return the work_group_name of the user currently logged in
###############################################################################
sub getCurrent_work_group_name {
    my $self = shift;

    # If the current_work_group_name is already known, return it
    if ($current_work_group_name gt "") { return $current_work_group_name; }
    if ($current_work_group_id < 1) {
      $current_work_group_id = $self->getCurrent_work_group_id();
    }

    # Extract the name from the database given the ID
    ($current_work_group_name) = $self->selectOneColumn(
        "SELECT work_group_name
           FROM $TB_WORK_GROUP
          WHERE work_group_id = $current_work_group_id
            AND record_status != 'D'
        ");

    return $current_work_group_name;
}


###############################################################################
# Return the active project_id of the user currently logged in
###############################################################################
sub getCurrent_project_id {
    my $self = shift;

    # If the current_project_id is already known, return it
    if ($current_project_id > 0) { return $current_project_id; }
    if ($current_contact_id < 1) { die "current_contact_id undefined!!"; }

    # Otherwise, see if it's in the user_context table
    ($current_project_id,$current_user_context_id) = $self->selectOneColumn(
        "SELECT project_id,user_context_id
           FROM $TB_USER_CONTEXT
          WHERE contact_id = $current_contact_id
            AND record_status != 'D'
        ");
    if ($current_project_id > 0) { return $current_project_id; }

    # This user has not selected an active project, so leave it 0
    $current_project_id = 0;

    return $current_project_id;
}


###############################################################################
# Return the active user_context_id of the user currently logged in
###############################################################################
sub getCurrent_user_context_id {
    my $self = shift;

    # If the current_user_context_id is already known, return it
    if ($current_user_context_id > 0) { return $current_user_context_id; }
    if ($current_contact_id < 1) { die "current_contact_id undefined!!"; }

    # Otherwise, see if it's in the user_context table
    ($current_user_context_id) = $self->selectOneColumn(
        "SELECT user_context_id
           FROM $TB_USER_CONTEXT
          WHERE contact_id = $current_contact_id
            AND record_status != 'D'
        ");

    return $current_user_context_id;
}


###############################################################################
# Return the active project_name of the user currently logged in
###############################################################################
sub getCurrent_project_name {
    my $self = shift;

    # If the current_project_name is already known, return it
    if ($current_project_name gt "") { return $current_project_name; }
    if ($current_project_id < 1) {
      $current_project_id = $self->getCurrent_project_id();
    }

    # If there is no current_project_id, return a name of "none"
    if ($current_project_id < 1) {
      $current_project_name = "[none]";
    } else {
      # Extract the name from the database given the ID
      ($current_project_name) = $self->selectOneColumn(
        "SELECT name
           FROM $TB_PROJECT
          WHERE project_id = $current_project_id
            AND record_status != 'D'
        ");
    }

    return $current_project_name;
}

###############################################################################
# 
###############################################################################
sub printLoginForm {
    my $self = shift;
    my $login_message = shift;

    my $table_name = $q->param('TABLE_NAME');

    print qq!
	<H2>$DBTITLE Login</H2>
	$LINESEPARATOR
    !;

    print qq!
	<TABLE WIDTH=$MESSAGE_WIDTH><TR><TD>
	$login_message
	</TD></TR></TABLE>
	$LINESEPARATOR
    ! if $login_message;

    print qq!
        <FORM METHOD="post">
        <TABLE BORDER=0><TR>
        <TD><B>Username:</B></TD>
        <TD><INPUT TYPE="text" NAME="username" SIZE=15></TD>
        </TR><TR>
        <TD><B>Password:</B></TD>
        <TD><INPUT TYPE="password" NAME="password" SIZE=15></TD>
        </TR><TR>
        <TD COLSPAN=2 ALIGN="center">
        <BR>
        <INPUT TYPE="submit" NAME="login" VALUE=" Login ">
        <INPUT TYPE="reset" VALUE=" Reset "></TD>
        <INPUT TYPE="hidden" NAME="TABLE_NAME" VALUE="$table_name"></TD>
        </TR></TABLE>
        </FORM>
        <B>There is a problem with Windows Internet Explorer in which you
        sometimes have to login twice before it takes effect.  This problem
        is being investigated.</B>
        $LINESEPARATOR
    !;
}


###############################################################################
# 
###############################################################################
sub printAuthErrors {
    my $self = shift;
    my $ra_errors = shift || \@ERRORS;

    my $back_button = $self->getGoBackButton();

    print qq!
        <CENTER>
        <H2>$DBTITLE Login Failed</H2>
        Your login failed because of the following Reasons.
        </CENTER>
        <BR><BR>
        <BLOCKQUOTE>
    !;

    foreach my $error (@{$ra_errors}) { print "<LI>$error<P>\n"; }

    print qq!
        </BLOCKQUOTE>
        <CENTER>
        $back_button
        </CENTER>
    !;
}


###############################################################################
# 
###############################################################################
sub destroyAuthHeader {
    my $self = shift;

    my $current_username = $self->getCurrent_username;
    my $logging_query="INSERT INTO $TB_USAGE_LOG
	(username,usage_action,result)
	VALUES ('$current_username','logout','SUCCESS')";
    $self->executeSQL($logging_query);

    my $cookie_path = $q->url(-absolute=>1);
    $cookie_path =~ s'/[^/]+$'/';

    my $cookie = $q->cookie(-name    => 'SBEAMSName',
                            -path    => "$cookie_path",
                            -value   => '0',
                            -expires => '-25h');
    $http_header = $q->header(-cookie => $cookie);

    return $http_header;
}


###############################################################################
# 
###############################################################################
sub createAuthHeader {
    my $self = shift;
    my $username = shift;

    my $cookie_path = $q->url(-absolute=>1);
    $cookie_path =~ s'/[^/]+$'/';
    
    my $cipher = new Crypt::CBC($SECRET_KEY, 'IDEA'); 
    my $encrypted_user = $cipher->encrypt("$username");

    my $cookie = $q->cookie(-name    => 'SBEAMSName',
                            -path    => "$cookie_path",
                            -value   => "$encrypted_user");
    my $head = $q->header(-cookie => $cookie);

    return $head;
}



###############################################################################
# fetch Errors
#
# Return a reference to the @ERRORS array
###############################################################################
sub fetchErrors {
    my $self = shift;

    return \@ERRORS || 0;
}


###############################################################################
# check Login
#
# Compare the supplied username and password with the login information in
# the database, and return success if the information is valid.
###############################################################################
sub checkLogin {
    my $self = shift;
    my $user = shift;
    my $pass = shift;
    my $logging_query = "";

    my $success = 0;

    my %query_result = $self->SelectTwoColumnHash(
        "SELECT username,password
           FROM $TB_USER_LOGIN
          WHERE username = '$user'
            AND record_status != 'D'
        ");

    unless ($query_result{$user}) {
        $query_result{$user} = $self->getUnixPassword($user);
    }

    @ERRORS  = ();
    if ($query_result{$user}) {

        if (crypt($pass, $query_result{$user}) eq $query_result{$user}) {
            $success = 1;
            $logging_query="INSERT INTO $TB_USAGE_LOG
		(username,usage_action,result)
		VALUES ('$user','login','SUCCESS')";
        } else {
            # Valid Login, Wrong Password
            # More useful message
            push(@ERRORS, "Incorrect Password for this Username");
            # Safer message
	    #push(@ERRORS, "Login Incorrect");
            $success = 0;
            $logging_query="INSERT INTO $TB_USAGE_LOG
		(username,usage_action,result)
		VALUES ('$user','login','INCORRECT PASSWORD')";
        }
    } else {
        # More useful message
        push(@ERRORS, "$user is not a valid Username in this system");
        # Safer message
        #push(@ERRORS, "Login Incorrect");
        $success = 0;
        $logging_query="INSERT INTO $TB_USAGE_LOG
		(username,usage_action,result)
		VALUES ('$user','login','UNKNOWN USER')";
    }

    $self->executeSQL($logging_query);

    return $success;
}


###############################################################################
# getUnixPassword
#
# Return the (encrypted) yp passwd for the supplied user
###############################################################################
sub getUnixPassword {
    my $self = shift;
    my $username = shift;
    my $password = 0;

    # Set PATH to something innocuous to keep Taint happy
    $ENV{PATH}="/bin:/usr/bin";

    # Collect the list of all passwds.  Using ypmatch would be more
    # efficient, but sending user-supplied data to a shell is dangerous
    my @results = `/usr/bin/ypcat passwd`;
    my @row;
    my ($uname,$pword);
    my $element;

    foreach $element (@results) {
        ($uname,$pword)=split(":",$element);
        last if ($uname eq $username);
    }

    if ($uname eq $username) {
        $password = $pword;
    }

    return $password;
}


###############################################################################
# check If Admin
#
# Return a TRUE value if the supplied username is an Administrator
###############################################################################
sub checkIfAdmin {
    my $self = shift;
    my $username = shift;

    my $valid_admin = 0;
    my $sql_query = qq!
        SELECT U.privilege_id,P.name
          FROM $TB_USER_LOGIN U
          JOIN $TB_PRIVILEGE P ON ( U.privilege_id=P.privilege_id )
         WHERE username = '$username'!;

    $dbh = $self->getDBHandle();
    my $sth = $dbh->prepare("$sql_query") or croak $dbh->errstr;
    my $rv  = $sth->execute or croak $dbh->errstr;

    my @row = $sth->fetchrow_array;
    $valid_admin = $username if ($row[1] eq "administrator");

    $sth->finish;

    push(@ERRORS, "$username is NOT an Administrator") unless $valid_admin;

    return $valid_admin;
}


###############################################################################
# 
###############################################################################
sub getContact_id {
    my $self = shift;
    my $username = shift;

    my $sql_query = qq!
	SELECT contact_id
	  FROM $TB_USER_LOGIN
	 WHERE username = '$username'!;

    my ($contact_id) = $self->selectOneColumn($sql_query);

    return $contact_id;
}


###############################################################################
# 
###############################################################################
sub getUsername {
    my $self = shift;
    my $contact_id = shift;

    my $sql_query = qq!
	SELECT username
	  FROM $TB_USER_LOGIN
	 WHERE contact_id = '$contact_id'!;

    my ($username) = $self->selectOneColumn($sql_query);

    return $username;
}




###############################################################################

1;

__END__
###############################################################################
###############################################################################
###############################################################################

=head1 NAME

SBEAMS::Connection::Authenticator - Perl extension for common authentication methods

=head1 SYNOPSIS

  Used as part of SBEAMS 

    use SBEAMS::Connection;
    $adb = new SBEAMS::Connection;

    $adb->printAuthErrors();

    $adb->printLoginForm($loginmessage);

    $adb->destroyAuthHeader();

    $adb->createAuthHeader($user_name);

    $adb->checkLoggedIn();

    $adb->fetchErrors();

    $adb->checkLogin($user_name, $password);

    $adb->checkIfUploader($user_name);

    $adb->checkIfAdmin($user_name);

    $adb->checkUserHasAccess($user_name, $experiment_name);

=head1 DESCRIPTION

    This module is inherited by the SBEAMS::Connection module,
    although it can be used on its own.  Its main function
    is to provide a set of authentication methods for
    this application.

    It uses cookie authentication, where when a user logs 
    in successfully through a web form, a cookie is placed in 
    the users web browser.  WebInterface then knows how to look for
    and find this cookie, and can then tell who the user is, and 
    if they have been authenticated to use the interface or not.
    

=head1 METHODS

=item B<checkLoggedIn()>

    Checks to see if the current user is logged in.  This
    is done by searcing for the cookie that SBEAMS places
    in the users web browser when they first log in.

    (Errors will be loaded into the ERROR array, to be retrieved 
     with fetchErrors() or printed with printAuthErrors())

    Accepts: null
        
    Returns: $scalar
        login_name for success
        0          for failure

=item B<printLoginForm($loginmessage)>

    Prints a standard login form. A text box for the username, 
    a text box for a password, and a submit button.  A message 
    can also be printed above the form, if one is passed in.

    Accepts: $scalar or null 

    Returns: 
        1 for success

=item B<checkLogin($user_name, $password)>

    Checks the username and password to see if the user has
    an account to access this application, and if the
    supplied password is correct.

    (Errors will be loaded into the @ERROR array, to be retrieved 
     with fetchErrors() or printed with printAuthErrors())

    Accepts: $user_name, $password (both are required!)

    Returns: 
        1 for success
        0 for failure

=item B<fetchErrors()>

    Simply returns an array of errors, or reasons, that a 
    method was not successful. (ex: "Invalid username", 
    "Wrong password", ...)  

    Accepts: null

    Returns: 
        @array if there are errors
        0      if there are no errors

=item B<printAuthErrors()>

    Prints the errors, or resaons, that a mthod was not
    successfull in a nice HTML list.  You can use this 
    method rather than retrieving the array and generating
    the HTML list yourself.

    Accepts: null

    Returns: 
        1 for success

=item B<createAuthHeader($user_name)>

    Creates a cookie header that will place the users 
    username in their browser so that we can retrieve it later.

    Accepts: $user_name

    Returns:
        1 for success

=item B<destroyAuthHeader()>

    Call this when a user want's to log out.  This will remove 
    the cookie that we placed in the users browser, and require 
    them to enter their username and password the next time they 
    want to access any part of this interface. 

    Accepts: null

    Returns:
        1 for success

=item B<checkIfUploader($user_name)>

    Checks the database to find out if the user has uploader 
    privelages to load experiments into this system.  

    (Errors will be loaded into the @ERROR array, to be retrieved 
     with fetchErrors() or printed with printAuthErrors())

    Accepts: $user_name

    Returns:
        $username for success
        0         for failure

=item B<checkIfAdmin($user_name)>

    Checks the database to find out if the user has administrator
    privelages to control this system.

    (Errors will be loaded into the @ERROR array, to be retrieved
     with fetchErrors() or printed with printAuthErrors())

    Accepts: $user_name

    Returns:
        $username for success
        0         for failure

=item B<checkUserHasAccess($user_name, $experiment_name)>

    Checks the database to see if the usere really has access to 
    this experiment.  This is checked before any data is returned 
    to make sure that a user can not access another users data.

    (Errors will be loaded into the @ERROR array, to be retrieved
     with fetchErrors() or printed with printAuthErrors())

    Accepts: $user, $experiment (name or id for either is fine)

    Returns:
        'OK' for success
        0    for failure

=item B<getUsersID($user_name)>

    Gets the user id number for this user.  Commonly used by other 
    methods of this system.

    Returns:
        $user_id for success
        0        for failure

=head1 AUTHOR

Eric Deutsch <edeutsch@systemsbiology.org>

=head1 SEE ALSO

perl(1).

=cut
