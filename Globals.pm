=head1 NAME

CGI::WPM::Globals - Perl module that is used by all subclasses of CGI::WPM::Base
for managing global program settings, file system and web site hierarchy
contexts, providing environment details, gathering and managing user input,
collecting and sending user output, and providing utilities like sending e-mail.

=cut

######################################################################

package CGI::WPM::Globals;
require 5.004;

# Copyright (c) 1999-2001, Darren R. Duncan. All rights reserved. This module is
# free software; you can redistribute it and/or modify it under the same terms as
# Perl itself.  However, I do request that this copyright information remain
# attached to the file.  If you modify this module and redistribute a changed
# version then please attach a note listing the modifications.

use strict;
use vars qw($VERSION @ISA);
$VERSION = '0.35';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	CGI::WPM::FileVirtualPath 0.35
	CGI::WPM::WebUserIO 0.94
	CGI::WPM::PageMaker 1.02

=cut

######################################################################

use CGI::WPM::FileVirtualPath 0.35;
use CGI::WPM::WebUserIO 0.94;
use CGI::WPM::PageMaker 1.02;
@ISA = qw( CGI::WPM::WebUserIO CGI::WPM::PageMaker );

######################################################################

=head1 SYNOPSIS

=head2 Complete Example Of A Main Program

	#!/usr/bin/perl
	use strict;
	use lib '/path/to/extra/perl/modules';

	require CGI::WPM::Globals;  # to hold our input, output, preferences
	my $globals = CGI::WPM::Globals->new( "/path/to/site/files" );  # get input

	if( $globals->user_input_param( 'debugging' ) eq 'on' ) {  # when owner's here
		$globals->is_debug( 1 );  # let us keep separate logs when debugging
		$globals->persistant_user_input_param( 'debugging', 1 );  # remember...
	}

	$globals->user_vrp( lc( $globals->user_input_param(  # fetch extra path info...
		$globals->vrp_param_name( 'path' ) ) ) );  # to know what page user wants
	$globals->current_user_vrp_level( 1 );  # get ready to examine start of vrp
	
	$globals->site_title( 'Sample Web Site' );  # use this in e-mail subjects
	$globals->site_owner_name( 'Darren Duncan' );  # send messages to him
	$globals->site_owner_email( 'darren@sampleweb.net' );  # send messages here
	$globals->site_owner_email_vrp( '/mailme' );  # site page email form is on

	require CGI::WPM::MultiPage;  # all content is made through here
	$globals->move_current_srp( 'content' );  # subdir holding content files
	$globals->move_site_prefs( 'content_prefs.pl' );  # configuration file
	CGI::WPM::MultiPage->execute( $globals );  # do all the work
	$globals->restore_site_prefs();  # rewind configuration context
	$globals->restore_last_srp();  # rewind subdir context

	require CGI::WPM::Usage;  # content is done, log usage though here
	$globals->move_current_srp( $globals->is_debug() ? 'usage_debug' : 'usage' );
	$globals->move_site_prefs( '../usage_prefs.pl' );  # configuration file
	CGI::WPM::Usage->execute( $globals );
	$globals->restore_site_prefs();
	$globals->restore_last_srp();

	if( $globals->is_debug() ) {
		$globals->body_append( <<__endquote );
	<P>Debugging is currently turned on.</P>  # give some user feedback
	__endquote
	}

	$globals->add_later_replace( {  # do some token substitutions
		__mailme_url__ => "__vrp_id__=/mailme",
		__external_id__ => "__vrp_id__=/external&url",
	} );

	$globals->add_later_replace( {  # more token substitutions in static pages
		__vrp_id__ => $globals->persistant_vrp_url(),
	} );

	$globals->send_to_user();  # send output now that everything's ready
	
	if( my @errs = $globals->get_errors() ) {  # log problems for check later
		foreach my $i (0..$#errs) {
			chomp( $errs[$i] );  # save on duplicate "\n"s
			print STDERR "Globals->get_error($i): $errs[$i]\n";
		}
	}

	1;

=head2 The Configuration File "content_prefs.pl"

	my $rh_preferences = { 
		page_header => <<__endquote,
	__endquote
		page_footer => <<__endquote,
	<P><EM>Sample Web Site was created and is maintained for personal use by 
	<A HREF="__mailme_url__">Darren Duncan</A>.  All content and source code was 
	created by me, unless otherwise stated.  Content that I did not create is 
	used with permission from the creators, who are appropriately credited where 
	it is used and in the <A HREF="__vrp_id__=/cited">Works Cited</A> section of 
	this site.</EM></P>
	__endquote
		page_css_code => [
			'BODY {background-color: white; background-image: none}'
		],
		page_replace => {
			__graphics_directories__ => 'http://www.sampleweb.net/graphics_directories',
			__graphics_webring__ => 'http://www.sampleweb.net/graphics_webring',
		},
		vrp_handlers => {
			external => {
				wpm_module => 'CGI::WPM::Redirect',
				wpm_prefs => {},
			},
			frontdoor => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'frontdoor.html' },
			},
			intro => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'intro.html' },
			},
			whatsnew => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'whatsnew.html' },
			},
			timelines => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'timelines.html' },
			},
			indexes => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'indexes.html' },
			},
			cited => {
				wpm_module => 'CGI::WPM::MultiPage',
				wpm_subdir => 'cited',
				wpm_prefs => 'cited_prefs.pl',
			},
			mailme => {
				wpm_module => 'CGI::WPM::MailForm',
				wpm_prefs => {},
			},
			guestbook => {
				wpm_module => 'CGI::WPM::GuestBook',
				wpm_prefs => {
					custom_fd => 1,
					field_defn => 'guestbook_questions.txt',
					fd_in_seqf => 1,
					fn_messages => 'guestbook_messages.txt',
				},
			},
			links => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'links.html' },
			},
			webrings => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'webrings.html' },
			},
		},
		def_handler => 'frontdoor',
	};

=head1 DESCRIPTION

I<This POD is coming when I get the time to write it.>

Subdirectories are all relative, so having '' means the current directory, 
'something' is a level down, '..' is a level up, '../another' is a level 
sideways, 'one/more/time' is 3 levels down.  However, any relative subdir 
beginning with '/' becomes absolute, where '/' corresponds to the site file 
root.  You can not go to parents of the site root.  Those are physical 
directories (site resource path), and the uri does not reflect them.  The uri 
does, however, reflect uri changes (virtual resource path).  

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 FUNCTIONS AND METHODS

This module inherits the full public interfaces and functionality of both 
CGI::WebUserInput and CGI::WebUserOutput, so the POD in those modules is also 
applicable to this one.  However, the new() and initialize() and clone() methods 
of those modules are overridden by ones defined in this one.

I<This POD is coming when I get the time to write it.>

	new([ ROOT[, DELIM[, PREFS[, USER_INPUT]]] ])
	initialize([ ROOT[, DELIM[, PREFS[, USER_INPUT]]] ])
	clone([ CLONE ]) -- POD for this available below
	
	send_content_to_user([ CONTENT ]) -- overrides CGI::WPM::WebUserIO's version

	is_debug([ NEW_VALUE ])

	get_errors()
	get_error([ INDEX ])
	add_error( MESSAGE )
	add_no_error()
	add_filesystem_error( FILENAME, UNIQUE_STR )

	site_root_dir([ NEW_VALUE ])
	system_path_delimiter([ NEW_VALUE ])
	phys_filename_string( FILENAME )

	site_prefs([ NEW_VALUES ])
	move_site_prefs([ NEW_VALUES ])
	restore_site_prefs()
	site_pref( NAME[, NEW_VALUE] )

	site_resource_path([ NEW_VALUE ])
	site_resource_path_string()
	move_current_srp([ CHANGE_VECTOR ])
	restore_last_srp()
	srp_child( FILENAME )
	srp_child_string( FILENAME[, SUFFIX] )

	virtual_resource_path([ NEW_VALUE ])
	virtual_resource_path_string()
	move_current_vrp([ CHANGE_VECTOR ])
	restore_last_vrp()
	vrp_child( FILENAME )
	vrp_child_string( FILENAME[, SUFFIX] )

	user_vrp([ NEW_VALUE ])
	user_vrp_string()
	current_user_vrp_level([ NEW_VALUE ])
	inc_user_vrp_level()
	dec_user_vrp_level()
	current_user_vrp_element([ NEW_VALUE ])

	vrp_param_name([ NEW_VALUE ])
	persistant_vrp_url([ CHANGE_VECTOR ])

	smtp_host([ NEW_VALUE ])
	smtp_timeout([ NEW_VALUE ])
	site_title([ NEW_VALUE ])
	site_owner_name([ NEW_VALUE ])
	site_owner_email([ NEW_VALUE ])
	site_owner_email_vrp([ NEW_VALUE ])
	site_owner_email_html([ VISIBLE_TEXT ])

	today_date_utc()

	get_hash_from_file( PHYS_PATH )
	get_prefs_rh( FILENAME )

=cut

######################################################################

# Names of properties for objects of this class are declared here:

# This property is set by the calling code and may affect how certain 
# areas of the program function, but it can be safely ignored.
my $KEY_IS_DEBUG = 'is_debug';  # are we debugging the site or not?

# This property is set when a server-side problem causes the program 
# to not function correctly.  This includes inability to load modules, 
# inability to get preferences, inability to use e-mail or databases.
my $KEY_SITE_ERRORS = 'site_errors'; # holds error string list, if any

# These properties are set by the code which instantiates this object,
# are operating system specific, and indicate where all the support 
# files are for a site. -- now inside $KEY_SRP

# These properties maintain recursive copies of themselves such that 
# subordinate page making modules can inherit (or override) properties 
# of their parents, but any changes made won't affect the properties 
# that the parents see (unless the parents allow it).
my $KEY_PREFS   = 'site_prefs';  # settings from files in the srp
my $KEY_SRP = 'srp_elements';  # site resource path (files)
my $KEY_VRP = 'vrp_elements';  # virtual resource path (url)
	# the above vrp is used soley when constructing new urls
my $KEY_PREFS_STACK = 'prefs_stack';
my $KEY_SRP_STACK   = 'srp_stack';
my $KEY_VRP_STACK   = 'vrp_stack';

# These properties are not recursive, but are unlikely to get edited
my $KEY_USER_VRP = 'user_vrp';   # vrp that user is requesting

# These properties are used under the assumption that the vrp which 
# the user provides us is in the query string.
my $KEY_VRP_UIPN = 'uipn_vrp';  # query param that has vrp as its value

# These properties are used in conjunction with sending e-mails.
my $KEY_SMTP_HOST    = 'smtp_host';    # what computer sends our mail
my $KEY_SMTP_TIMEOUT = 'smtp_timeout'; # how long wait for mail send
my $KEY_SITE_TITLE   = 'site_title';   # name of site
my $KEY_OWNER_NAME   = 'owner_name';   # name of site's owner
my $KEY_OWNER_EMAIL  = 'owner_email';  # e-mail of site's owner
my $KEY_OWNER_EM_VRP = 'owner_em_vrp'; # vrp for e-mail page

# Constant values used in this class go here:

my $DEF_VRP_UIPN = 'path';

my $TALB = '[';  # left side of bounds for token replacement arguments
my $TARB = ']';  # right side of same

my $DEF_SMTP_HOST = 'localhost';
my $DEF_SMTP_TIMEOUT = 30;
my $DEF_SITE_TITLE = 'Untitled Website';

######################################################################

sub new {
	my $class = shift( @_ );
	my $self = bless( {}, ref($class) || $class );
	$self->initialize( @_ );
	return( $self );
}

######################################################################

sub initialize {
	my ($self, $root, $delim, $prefs, $user_input) = @_;

	$self->CGI::WPM::WebUserIO::initialize( $user_input );
	$self->CGI::WPM::PageMaker::initialize();
	
	%{$self} = (
		%{$self},
		
		$KEY_IS_DEBUG => undef,
		
		$KEY_SITE_ERRORS => [],
		
		$KEY_PREFS => {},
		$KEY_SRP   => CGI::WPM::FileVirtualPath->new(),
		$KEY_VRP   => CGI::WPM::FileVirtualPath->new(),
		$KEY_PREFS_STACK => [],
		$KEY_SRP_STACK   => [],
		$KEY_VRP_STACK   => [],
		
		$KEY_USER_VRP => CGI::WPM::FileVirtualPath->new(),
		
		$KEY_VRP_UIPN => $DEF_VRP_UIPN,
		
		$KEY_SMTP_HOST => $DEF_SMTP_HOST,
		$KEY_SMTP_TIMEOUT => $DEF_SMTP_TIMEOUT,
		$KEY_SITE_TITLE => $DEF_SITE_TITLE,
		$KEY_OWNER_NAME => undef,
		$KEY_OWNER_EMAIL => undef,
		$KEY_OWNER_EM_VRP => undef,
	);

	$self->site_root_dir( $root );
	$self->system_path_delimiter( $delim );
	$self->site_prefs( $prefs );
}

######################################################################

=head2 clone([ CLONE ])

This method initializes a new object to have all of the same properties of the
current object and returns it.  This new object can be provided in the optional
argument CLONE (if CLONE is an object of the same class as the current object);
otherwise, a brand new object of the current class is used.  Only object 
properties recognized by CGI::WPM::Globals are set in the clone; other properties 
are not changed.

=cut

######################################################################

sub clone {
	my ($self, $clone, @args) = @_;
	ref($clone) eq ref($self) or $clone = bless( {}, ref($self) );
	$clone = $self->CGI::WPM::WebUserIO::clone( $clone );
	$clone = $self->CGI::WPM::PageMaker::clone( $clone );
	
	$clone->{$KEY_IS_DEBUG} = $self->{$KEY_IS_DEBUG};

	$clone->{$KEY_SITE_ERRORS} = [@{$self->{$KEY_SITE_ERRORS}}];
	
	$clone->{$KEY_PREFS} = {%{$self->{$KEY_PREFS}}};
	$clone->{$KEY_SRP} = $self->{$KEY_SRP}->clone();
	$clone->{$KEY_VRP} = $self->{$KEY_VRP}->clone();
	$clone->{$KEY_PREFS_STACK} = [@{$self->{$KEY_PREFS_STACK}}];
	$clone->{$KEY_SRP_STACK} = [map { $_->clone() } @{$self->{$KEY_SRP_STACK}}];
	$clone->{$KEY_VRP_STACK} = [map { $_->clone() } @{$self->{$KEY_VRP_STACK}}];

	$clone->{$KEY_USER_VRP} = $self->{$KEY_USER_VRP}->clone();

	$clone->{$KEY_VRP_UIPN} = $self->{$KEY_VRP_UIPN};

	$clone->{$KEY_SMTP_HOST} = $self->{$KEY_SMTP_HOST};
	$clone->{$KEY_SMTP_TIMEOUT} = $self->{$KEY_SMTP_TIMEOUT};
	$clone->{$KEY_SITE_TITLE} = $self->{$KEY_SITE_TITLE};
	$clone->{$KEY_OWNER_NAME} = $self->{$KEY_OWNER_NAME};
	$clone->{$KEY_OWNER_EMAIL} = $self->{$KEY_OWNER_EMAIL};
	$clone->{$KEY_OWNER_EM_VRP} = $self->{$KEY_OWNER_EM_VRP};

	return( $clone );
}

######################################################################
# Override same-named method in CGI::WPM::WebUserIO to acknowledge that we 
# now store the page content within ourself.

sub send_content_to_user {
	my ($self, $content) = @_;
	defined( $content ) or $content = $self->content_as_string();
	$self->SUPER::send_content_to_user( $content );
}

######################################################################

sub is_debug {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_IS_DEBUG} = $new_value;
	}
	return( $self->{$KEY_IS_DEBUG} );
}

######################################################################

sub get_errors {
	return( grep { defined($_) } @{$_[0]->{$KEY_SITE_ERRORS}} );
}

sub get_error {
	my ($self, $index) = @_;
	defined( $index ) or $index = -1;
	return( $self->{$KEY_SITE_ERRORS}->[$index] );
}

sub add_error {
	my ($self, $message) = @_;
	return( push( @{$self->{$KEY_SITE_ERRORS}}, $message ) );
}

sub add_no_error {
	push( @{$_[0]->{$KEY_SITE_ERRORS}}, undef );
}

sub add_filesystem_error {
	my ($self, $filename, $unique_part) = @_;
	my $filepath = $self->srp_child_string( $filename );
	return( $self->add_error( "can't $unique_part file '$filepath': $!" ) );
}

######################################################################

sub site_root_dir {
	my ($self, $new_value) = @_;
	return( $self->{$KEY_SRP}->physical_root( $new_value ) );
}

sub system_path_delimiter {
	my ($self, $new_value) = @_;
	return( $self->{$KEY_SRP}->physical_delimiter( $new_value ) );
}

sub phys_filename_string {
	my ($self, $chg_vec, $trailer) = @_;
	return( $self->{$KEY_SRP}->physical_child_path_string( $chg_vec, $trailer ) );
}

######################################################################

sub site_prefs {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_PREFS} = $self->get_prefs_rh( $new_value ) || {};
	}
	return( $self->{$KEY_PREFS} );
}

sub move_site_prefs {
	my ($self, $new_value) = @_;
	push( @{$self->{$KEY_PREFS_STACK}}, $self->{$KEY_PREFS} );
	$self->{$KEY_PREFS} = $self->get_prefs_rh( $new_value ) || {};
}

sub restore_site_prefs {
	my $self = shift( @_ );
	$self->{$KEY_PREFS} = pop( @{$self->{$KEY_PREFS_STACK}} ) || {};
}

sub site_pref {
	my $self = shift( @_ );
	my $key = shift( @_ );

	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_PREFS}->{$key} = $new_value;
	}
	my $value = $self->{$KEY_PREFS}->{$key};

	# if current version doesn't define key, look in older versions
	unless( defined( $value ) ) {
		foreach my $prefs (reverse @{$self->{$KEY_PREFS_STACK}}) {
			$value = $prefs->{$key};
			defined( $value ) and last;
		}
	}
	
	return( $value );
}

######################################################################

sub site_resource_path {
	my ($self, $new_value) = @_;
	return( $self->{$KEY_SRP}->path( $new_value ) );
}

sub site_resource_path_string {
	my ($self, $trailer) = @_;
	return( $self->{$KEY_SRP}->path_string( $trailer ) );
}
	
sub move_current_srp {
	my ($self, $chg_vec) = @_;
	push( @{$self->{$KEY_SRP_STACK}}, $self->{$KEY_SRP} );
	$self->{$KEY_SRP} = $self->{$KEY_SRP}->child_path_obj( $chg_vec );
}

sub restore_last_srp {
	my ($self) = @_;
	if( @{$self->{$KEY_SRP_STACK}} ) {
		$self->{$KEY_SRP} = pop( @{$self->{$KEY_SRP_STACK}} );
	}
}

sub srp_child {
	my ($self, $chg_vec) = @_;
	return( $self->{$KEY_SRP}->child_path( $chg_vec ) );
}

sub srp_child_string {
	my ($self, $chg_vec, $trailer) = @_;
	return( $self->{$KEY_SRP}->child_path_string( $chg_vec, $trailer ) );
}

######################################################################

sub virtual_resource_path {
	my ($self, $new_value) = @_;
	return( $self->{$KEY_VRP}->path( $new_value ) );
}

sub virtual_resource_path_string {
	my ($self, $trailer) = @_;
	return( $self->{$KEY_VRP}->path_string( $trailer ) );
}
	
sub move_current_vrp {
	my ($self, $chg_vec) = @_;
	push( @{$self->{$KEY_VRP_STACK}}, $self->{$KEY_VRP} );
	$self->{$KEY_VRP} = $self->{$KEY_VRP}->child_path_obj( $chg_vec );
}

sub restore_last_vrp {
	my ($self) = @_;
	if( @{$self->{$KEY_VRP_STACK}} ) {
		$self->{$KEY_VRP} = pop( @{$self->{$KEY_VRP_STACK}} );
	}
}

sub vrp_child {
	my ($self, $chg_vec) = @_;
	return( $self->{$KEY_VRP}->child_path( $chg_vec ) );
}

sub vrp_child_string {
	my ($self, $chg_vec, $trailer) = @_;
	return( $self->{$KEY_VRP}->child_path_string( $chg_vec, $trailer ) );
}

######################################################################

sub user_vrp {
	my ($self, $new_value) = @_;
	return( $self->{$KEY_USER_VRP}->path( $new_value ) );
}

sub user_vrp_string {
	my ($self, $trailer) = @_;
	return( $self->{$KEY_USER_VRP}->path_string( $trailer ) );
}

sub current_user_vrp_level {
	my ($self, $new_value) = @_;
	return( $self->{$KEY_USER_VRP}->current_path_level( $new_value ) );
}

sub inc_user_vrp_level {
	my ($self) = @_;
	return( $self->{$KEY_USER_VRP}->inc_path_level() );
}

sub dec_user_vrp_level {
	my ($self) = @_;
	return( $self->{$KEY_USER_VRP}->dec_path_level() );
}

sub current_user_vrp_element {
	my ($self, $new_value) = @_;
	return( $self->{$KEY_USER_VRP}->current_path_element( $new_value ) );
}

######################################################################

sub vrp_param_name {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_VRP_UIPN} = $new_value;
	}
	return( $self->{$KEY_VRP_UIPN} );
}

# This currently supports vrp in query string format only.
# If no argument provided, returns "[base]?[pers]&path"
# If 1 argument provided, returns "[base]?[pers]&path=[vrp_child]"
# If 2 arguments provided, returns "[base]?[pers]&path=[vrp_child]/"

sub persistant_vrp_url {
	my $self = shift( @_ );
	my $chg_vec = shift( @_ );
	my $persist_input_str = $self->persistant_user_input_string();
	return( $self->base_url().'?'.
		($persist_input_str ? "$persist_input_str&" : '').
		$self->{$KEY_VRP_UIPN}.(defined( $chg_vec ) ? 
		'='.$self->vrp_child_string( $chg_vec, @_ ) : '') );
}

######################################################################

sub smtp_host {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_SMTP_HOST} = $new_value;
	}
	return( $self->{$KEY_SMTP_HOST} );
}

sub smtp_timeout {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_SMTP_TIMEOUT} = $new_value;
	}
	return( $self->{$KEY_SMTP_TIMEOUT} );
}

sub site_title {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_SITE_TITLE} = $new_value;
	}
	return( $self->{$KEY_SITE_TITLE} );
}

sub site_owner_name {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_OWNER_NAME} = $new_value;
	}
	return( $self->{$KEY_OWNER_NAME} );
}

sub site_owner_email {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_OWNER_EMAIL} = $new_value;
	}
	return( $self->{$KEY_OWNER_EMAIL} );
}

sub site_owner_email_vrp {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_OWNER_EM_VRP} = $new_value;
	}
	return( $self->{$KEY_OWNER_EM_VRP} );
}

sub site_owner_email_html {
	my $self = shift( @_ );
	my $visible_text = shift( @_ ) || 'e-mail';
	my $owner_vrp = $self->site_owner_email_vrp();
	my $owner_email = $self->site_owner_email();
	return( $owner_vrp ? '<A HREF="'.$self->persistant_vrp_url( 
		$owner_vrp ).'">'.$visible_text.'</A>' : '<A HREF="mailto:'.
		$owner_email.'">'.$visible_text.'</A> ('.$owner_email.')' );
}

######################################################################

sub today_date_utc {
	my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(time);
	$year += 1900;  # year counts from 1900 AD otherwise
	$mon += 1;      # ensure January is 1, not 0
	my @parts = ($year, $mon, $mday, $hour, $min, $sec);
	return( sprintf( "%4.4d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d UTC", @parts ) );
}

######################################################################
# Note: in order for this to work, the file must contain valid perl 
# code that, when compiled, produces a valid HASH reference.

sub get_hash_from_file {
	my ($self, $filename) = @_;
	my $result = do $filename;
	return( (ref( $result ) eq 'HASH') ? $result : undef );
}

######################################################################

sub get_prefs_rh {
	my ($self, $site_prefs) = @_;

	if( ref( $site_prefs ) eq 'HASH' ) {
		$site_prefs = {%{$site_prefs}};

	} else {
		$self->add_no_error();
		$site_prefs = $self->get_hash_from_file( 
				$self->phys_filename_string( $site_prefs ) ) or do {
			my $filename = $self->srp_child_string( $site_prefs );
			$self->add_error( <<__endquote );
can't obtain required site preferences hash from file "$filename": $!
__endquote
		};

	}
	return( $site_prefs );
}

######################################################################

1;
__END__

=head1 AUTHOR

Copyright (c) 1999-2001, Darren R. Duncan. All rights reserved. This module is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.  However, I do request that this copyright information remain
attached to the file.  If you modify this module and redistribute a changed
version then please attach a note listing the modifications.

I am always interested in knowing how my work helps others, so if you put this
module to use in any of your own code then please send me the URL.  Also, if you
make modifications to the module because it doesn't work the way you need, please
send me a copy so that I can roll desirable changes into the main release.

Address comments, suggestions, and bug reports to B<perl@DarrenDuncan.net>.

=head1 SEE ALSO

perl(1), CGI::WPM::PageMaker, CGI::WPM::WebUserIO, CGI::WPM::Base.

=cut
