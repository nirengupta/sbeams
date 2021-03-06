package SBEAMS::Connection::HTMLPrinter;

###############################################################################
# Program     : SBEAMS::Connection::HTMLPrinter
# Author      : Eric Deutsch <edeutsch@systemsbiology.org>
# $Id$
#
# Description : This is part of the SBEAMS::Connection module which handles
#               standardized parts of generating HTML.
#
#		This really begs to get a lot more object oriented such that
#		there are several different contexts under which the a user
#		can be in, and the header, button bar, etc. vary by context
###############################################################################


use strict;
use vars qw($current_contact_id $current_username
             $current_work_group_id $current_work_group_name
             $current_project_id $current_project_name $current_user_context_id);
use CGI::Carp qw(fatalsToBrowser croak);
use SBEAMS::Connection::DBConnector;
use SBEAMS::Connection::Settings;
use SBEAMS::Connection::Tables;
use SBEAMS::Connection::TableInfo;
use Env qw (HTTP_USER_AGENT);


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
# printPageHeader
###############################################################################
sub printPageHeader {
    my $self = shift;
    my %args = @_;

    my $navigation_bar = $args{'navigation_bar'} || "YES";
    my $minimal_header = $args{'minimal_header'} || "NO";

    my $http_header = $self->get_http_header();

    print qq~$http_header
	<HTML><HEAD>
	<TITLE>$DBTITLE - Systems Biology Experiment Analysis Management System</TITLE>
    ~;


    unless ($minimal_header eq "YES") {
        $self->printJavascriptFunctions();
        $self->printStyleSheet();
    }


    print qq~
	<!--META HTTP-EQUIV="Expires" CONTENT="Fri, Jun 12 1981 08:20:00 GMT"-->
	<!--META HTTP-EQUIV="Pragma" CONTENT="no-cache"-->
	<!--META HTTP-EQUIV="Cache-Control" CONTENT="no-cache"-->
	</HEAD>

	<!-- Background white, links blue (unvisited), navy (visited), red (active) -->
	<BODY BGCOLOR="#FFFFFF" TEXT="#000000" LINK="#0000FF" VLINK="#000080" ALINK="#FF0000" >
	<table border=0 width="100%" cellspacing=0 cellpadding=1>

	<!------- Header ------------------------------------------------>
	<a name="TOP"></a>
	<tr>
	  <td bgcolor="$BGCOLOR"><img height=50 width=50 border=0 alt="$DBTITLE Logo" src="$HTML_BASE_DIR/images/logo.gif"></td>
	  <td align="left" bgcolor="$BGCOLOR"><H1>$DBTITLE - Systems Biology Experiment Analysis Management System<BR>$DBVERSION</H1></td>
	</tr>
    ~;

    #print ">>>http_header=$http_header<BR>\n";

    if ($minimal_header eq "YES") {
      print qq~
	<!------- Button Bar -------------------------------------------->
	<tr><td bgcolor="$BGCOLOR" align="left" valign="top">
	<table border=0 width="120" cellpadding=2 cellspacing=0>

	<tr><td><a href="$HTML_BASE_DIR/"><b>$DBTITLE Home</b></a></td></tr>

	</table>
	</td>

	<!-------- Main Page ------------------------------------------->
	<td valign=top>
	<table border=0 width="680" bgcolor="#ffffff" cellpadding=10>
	<tr><td>
      ~;
      return;
    }


    if ($navigation_bar eq "YES") {
      print qq~
	<!------- Button Bar -------------------------------------------->
	<tr><td bgcolor="$BGCOLOR" align="left" valign="top">
	<table border=0 width="120" cellpadding=2 cellspacing=0>

	<tr><td><a href="$CGI_BASE_DIR/main.cgi">>$DBTITLE Home</a></td></tr>
	<tr><td><a href="$CGI_BASE_DIR/MicroArrayMain.cgi">>MicroArray Home</a></td></tr>
	<tr><td><a href="$CGI_BASE_DIR/tools/main.cgi">>Tools Home</a></td></tr>
	<tr><td><a href="$CGI_BASE_DIR/logout.cgi">>Logout</a></td></tr>
	<tr><td>&nbsp;</td></tr>
	<tr><td><a href="$CGI_BASE_DIR/MicroArrayMain.cgi">- MicroArray</a></td></tr>
	<tr><td><a href="$CGI_BASE_DIR/tools/main.cgi">- Tools</a></td></tr>
	<tr><td>&nbsp;</td></tr>
	<tr><td><a href="$CGI_BASE_DIR/ManageTable.cgi?TABLE_NAME=user_login">- Admin</a></td></tr>
	</table>
	</td>

	<!-------- Main Page ------------------------------------------->
	<td valign=top>
	<table border=0 bgcolor="#ffffff" cellpadding=4>
	<tr><td>

      ~;
    } else {
      print qq~
	</TABLE>
      ~;
    }

}

# 	<table border=0 width="680" bgcolor="#ffffff" cellpadding=4>


###############################################################################
# printStyleSheet
#
# Print the standard style sheet for pages.  Use a font size of 10pt if
# remote client is on Windows, else use 12pt.  This ends up making fonts
# appear the same size on Windows+IE and Linux+Netscape.  Other tweaks for
# different browsers might be appropriate.
###############################################################################
sub printStyleSheet {
    my $self = shift;

    my $FONT_SIZE=12;
    my $FONT_SIZE_LG=14;
    my $FONT_SIZE_HG=16;
    if ( $HTTP_USER_AGENT =~ /Win/ ) {
      $FONT_SIZE=10;
      $FONT_SIZE_LG=12;
      $FONT_SIZE_HG=14;
    }

    print qq~
	<style type="text/css">
	//<!--
	body {  font-family: Arial Helvetica, sans-serif; font-size: ${FONT_SIZE}pt}
	th   {  font-family: Arial, Helvetica, sans-serif; font-size: ${FONT_SIZE}pt; font-weight: bold; background-color: #A0A0A0;}
	td   {  font-family: Arial, Helvetica, sans-serif; font-size: ${FONT_SIZE}pt;}
	form   {  font-family: Arial, Helvetica, sans-serif; font-size: ${FONT_SIZE}pt}
	h1   {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: ${FONT_SIZE_HG}pt; font-weight: bold}
	h2   {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: ${FONT_SIZE_LG}pt; font-weight: bold}
	h3   {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: ${FONT_SIZE_LG}pt}
	h4   {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: ${FONT_SIZE_LG}pt}
	A:link    {  font-family: Arial, Helvetica, sans-serif; font-size: ${FONT_SIZE}pt; text-decoration: none; color: blue}
	A:visited {  font-family: Arial, Helvetica, sans-serif; font-size: ${FONT_SIZE}pt; text-decoration: none; color: blue}
	A:hover   {  font-family: Arial, Helvetica, sans-serif; font-size: ${FONT_SIZE}pt; text-decoration: underline; color: red}
	A:link.nav {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #000000}
	A:visited.nav {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #000000}
	A:hover.nav {  font-family: Verdana, Arial, Helvetica, sans-serif; color: red;}
	.nav {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #000000}
	//-->
	</style>
    ~;

}


###############################################################################
# printJavascriptFunctions
#
# Print the standard Javascript functions that should appear at the top of
# most pages.  There probably should be some customization allowance here.
# Not sure how to design that yet.
###############################################################################
sub printJavascriptFunctions {
    my $self = shift;
    my $javascript_includes = shift;


    print qq~
	<SCRIPT LANGUAGE="JavaScript">
	<!--

	function refreshDocument() {
            //confirm( "apply_action ="+document.forms[0].apply_action.options[0].selected+"=");
            document.forms[0].apply_action_hidden.value = "REFRESH";
	    document.forms[0].submit();
	} // end refresh


	function showPassed(input_field) {
            //confirm( "input_field ="+input_field+"=");
            confirm( "selected option ="+document.forms[0].slide_id.options[document.forms[0].slide_id.selectedIndex].text+"=");
	    return;
	} // end showPassed


        // -->
        </SCRIPT>
    ~;

}


###############################################################################
# printMinimalPageHeader
###############################################################################
sub printMinimalPageHeader {
    my $self = shift;
    my $head = shift || "Content-type: text/html\n\n";
    
    print qq~$head
	<HTML>
	<HEAD><TITLE>$DBTITLE - Systems Biology Experiment Analysis Management System</TITLE></HEAD>

	<!-- Background white, links blue (unvisited), navy (visited), red (active) -->
	<BODY BGCOLOR="#FFFFFF" TEXT="#000000" LINK="#0000FF" VLINK="#000080" ALINK="#FF0000" >
	<table border=0 width="100%" cellspacing=1 cellpadding=3>

	<!------- Header ------------------------------------------------>
	<a name="TOP"></a>
	<tr>
	  <td><img height=100 width=100 border=0 alt="$DBTITLE Logo" src="$HTML_BASE_DIR/images/logo.gif"></td>
	  <td align="left"><H1>$DBTITLE - Systems Biology Experiment Analysis Management System<BR>$DBVERSION</H1></td>
	</tr>

	<!------- Button Bar -------------------------------------------->
	<tr><td align="left" valign="top">
	<table border=0 width="120" cellpadding=2 cellspacing=0>

	<tr><td><a href="$HTML_BASE_DIR/"><b>$DBTITLE Home</b></a></td></tr>

	</table>
	</td>

	<!-------- Main Page ------------------------------------------->
	<td valign=top>
	<table border=0 width="680" bgcolor="#ffffff" cellpadding=10>
	<tr><td>

    ~;

}


###############################################################################
# printUserContext
###############################################################################
sub printUserContext {
    my $self = shift;

    $current_username = $self->getCurrent_username;
    $current_contact_id = $self->getCurrent_contact_id;
    $current_work_group_id = $self->getCurrent_work_group_id;
    $current_work_group_name = $self->getCurrent_work_group_name;
    $current_project_id = $self->getCurrent_project_id;
    $current_project_name = $self->getCurrent_project_name;
    $current_user_context_id = $self->getCurrent_user_context_id;

    my $temp_current_work_group_name = $current_work_group_name;
    if ($current_work_group_name eq "Admin") {
      $temp_current_work_group_name = "<FONT COLOR=red><BLINK>$current_work_group_name</BLINK></FONT>";
    }

    print qq!
	Current Login: <B>$current_username</B> ($current_contact_id) &nbsp;
	Current Group: <B>$temp_current_work_group_name</B> ($current_work_group_id) &nbsp;
	Current Project: <B>$current_project_name</B> ($current_project_id)
	&nbsp; <A HREF="$CGI_BASE_DIR/ManageTable.cgi?TABLE_NAME=user_context&user_context_id=$current_user_context_id">[CHANGE]</A><BR>
    !;


}

###############################################################################
# printPageFooter
###############################################################################
sub printPageFooter {
  my $self = shift;
  my $flag = shift || "CloseTablesAndPrintFooter";

  if ($flag =~ /CloseTables/) {
    print qq~
	</TD></TR></TABLE>
	</TD></TR></TABLE>
    ~;
  }

  if ($flag =~ /Footer/) {
    print qq~
	<BR><HR SIZE="2" NOSHADE WIDTH="30%" ALIGN="LEFT">
	SBEAMS @ ISB [Under Development]<BR><BR><BR>
	</BODY></HTML>\n\n
    ~;
  }

}


###############################################################################
# getGoBackButton
###############################################################################
sub getGoBackButton {
  my $self = shift;

  my $button = qq~
	<FORM>
	<INPUT TYPE="button" NAME="back" VALUE="Go Back"
		onClick="history.back()">
	</FORM>
    ~;

  return $button;
}


###############################################################################
# Print Incomplete Form Message
###############################################################################
sub printIncompleteForm {
    my $self = shift;
    my $errors = shift;
    my $back_button = $self->getGoBackButton();
    print qq!
        <P>
        <H2>Incomplete Form</H2>
        $LINESEPARATOR
        <P>
        <TABLE WIDTH=$MESSAGE_WIDTH><TR><TD>
        All required form fields must be filled in. Please see the 
        errors listed below and click the Back button to return to 
        the form.
        <P>
        $errors 
        <P>
        <CENTER>
        $back_button
        </CENTER>
        </TD></TR></TABLE>
        $LINESEPARATOR
        <P>!;
} # end printIncompleteForm




###############################################################################

1;

__END__
###############################################################################
###############################################################################
###############################################################################

=head1 NAME

SBEAMS::Connection::HTMLPrinter - Perl extension for common HTML printing methods

=head1 SYNOPSIS

  Used as part of this system

    use SBEAMS::Connection;
    $adb = new SBEAMS::Connection;

    $adb->printPageHeader();

    $adb->printPageFooter();

    $adb->getGoBackButton();

=head1 DESCRIPTION

    This module is inherited by the SBEAMS::Connection module,
    although it can be used on its own.  Its main function 
    is to encapsulate common HTML printing routines used by
    this application.

=head1 METHODS

=item B<printPageHeader()>

    Prints the common HTML header used by all HTML pages generated 
    by theis application

=item B<printPageFooter()>

    Prints the common HTML footer used by all HTML pages generated 
    by this application

=item B<getGoBackButton()>

    Returns a form button, coded with javascript, so that when it 
    is clicked the user is returned to the previous page in the 
    browser history.

=head1 AUTHOR

Eric Deutsch <edeutsch@systemsbiology.org>

=head1 SEE ALSO

perl(1).

=cut
