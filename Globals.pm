=head1 NAME

CGI::WPM::Globals - Perl module that is used by all subclasses of CGI::WPM::Base
for managing global program settings, file system and web site hierarchy
contexts, providing environment details, gathering and managing user input,
collecting and sending user output.

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
$VERSION = '0.36';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	Apache (when running under mod_perl only)
	HTTP::Headers 1.36 (earlier versions may work, but not tested)

=head2 Nonstandard Modules

	CGI::MultiValuedHash 1.06
	CGI::WPM::FileVirtualPath 0.36
	HTML::EasyTags 1.03  # required in content_as_string() method only

=cut

######################################################################

use CGI::MultiValuedHash 1.06;
use CGI::WPM::FileVirtualPath 0.36;

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

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 UNDOCUMENTED FUNCTIONS AND METHODS

I<This POD is coming when I get the time to write it.>

	new([ ROOT[, DELIM[, PREFS[, USER_INPUT]]] ])
	initialize([ ROOT[, DELIM[, PREFS[, USER_INPUT]]] ])
	clone([ CLONE ]) -- POD for this available below
	
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

	get_hash_from_file( PHYS_PATH )
	get_prefs_rh( FILENAME )

	is_mod_perl()

	user_cookie_str()
	user_query_str()
	user_post_str()
	user_offline_str()
	is_oversize_post()

	request_method()
	content_length()

	server_name()
	virtual_host()
	server_port()
	script_name()

	http_referer()

	remote_addr()
	remote_host()
	remote_user()
	user_agent()

	base_url()
	self_url()
	self_post([ LABEL ])
	self_html([ LABEL ])

	user_cookie([ NEW_VALUES ])
	user_cookie_string()
	user_cookie_param( KEY[, NEW_VALUES] )

	user_input([ NEW_VALUES ])
	user_input_string()
	user_input_param( KEY[, NEW_VALUE] )
	user_input_keywords()

	persistant_user_input_params([ NEW_VALUES ])
	persistant_user_input_string()
	persistant_user_input_param( KEY[, NEW_VALUES] )
	persistant_url()

	redirect_url([ NEW_VALUE ]) -- POD for this available below
	
	get_http_headers()
	
	send_headers_to_user([ HTTP ])
	send_content_to_user([ CONTENT ])
	send_to_user([ HTTP[, CONTENT] ])
	
	parse_url_encoded_cookies( DO_LC_KEYS, ENCODED_STRS )
	parse_url_encoded_queries( DO_LC_KEYS, ENCODED_STRS )

=head1 DOCUMENTED FUNCTIONS AND METHODS

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

# Names of properties for objects of this class are declared here:

# These properties are set only once because they correspond to user 
# input that can only be gathered prior to this program starting up.
my $KEY_INITIAL_UI = 'ui_initial_user_input';
	my $IKEY_COOKIE   = 'user_cookie_str'; # cookies from browser
	my $IKEY_QUERY    = 'user_query_str';  # query str from browser
	my $IKEY_POST     = 'user_post_str';   # post data from browser
	my $IKEY_OFFLINE  = 'user_offline_str'; # shell args / redirect
	my $IKEY_OVERSIZE = 'is_oversize_post'; # true if cont len >max

# These properties are not recursive, but are unlikely to get edited
my $KEY_USER_COOKIE = 'ui_user_cookie'; # settings from browser cookies
my $KEY_USER_INPUT  = 'ui_user_input';  # settings from browser query/post

# These properties keep track of important user/pref data that should
# be returned to the browser even if not recognized by subordinates.
my $KEY_PERSIST_QUERY  = 'ui_persist_query';  # which qp persist for session
	# this is used only when constructing new urls, and it stores just 
	# the names of user input params whose values we are to return.

# These properties relate to output headers
my $KEY_REDIRECT_URL = 'uo_redirect_url';  # if def, str is redir header

# Constant values used in this class go here:

my $MAX_CONTENT_LENGTH = 100_000;  # currently limited to 100 kbytes
my $UIP_KEYWORDS = '.keywords';  # user input param for ISINDEX queries

# Names of properties for objects of this class are declared here:
my $KEY_MAIN_BODY = 'uo_main_body';  # array of text -> <BODY>*</BODY>
my $KEY_MAIN_HEAD = 'uo_main_head';  # array of text -> <HEAD>*</HEAD>
my $KEY_TITLE     = 'uo_title';      # scalar of document title -> head
my $KEY_AUTHOR    = 'uo_author';     # scalar of document author -> head
my $KEY_META      = 'uo_meta';       # hash of meta keys/values -> head
my $KEY_CSS_SRC   = 'uo_css_src';    # array of text -> head
my $KEY_CSS_CODE  = 'uo_css_code';   # array of text -> head
my $KEY_BODY_ATTR = 'uo_body_attr';  # hash of attrs -> <BODY *>
my $KEY_REPLACE   = 'uo_replace';  # array of hashes, find and replace

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

	if( $self->is_mod_perl() ) {
		require Apache;
		$| = 1;
	}
	
	$self->{$KEY_INITIAL_UI} ||= $self->get_initial_user_input();
	
	$self->{$KEY_USER_COOKIE} = $self->parse_url_encoded_cookies( 1, 
		$self->user_cookie_str() 
	);
	$self->{$KEY_USER_INPUT} = $self->parse_url_encoded_queries( 1, 
		$self->user_query_str(), 
		$self->user_post_str(), 
		$self->user_offline_str() 
	);
	$self->{$KEY_PERSIST_QUERY} = {};
	$self->{$KEY_REDIRECT_URL} = undef;
	
	$self->user_input( $user_input );

	$self->{$KEY_MAIN_BODY} = [];
	$self->{$KEY_MAIN_HEAD} = [];
	$self->{$KEY_TITLE} = undef;
	$self->{$KEY_AUTHOR} = undef;
	$self->{$KEY_META} = {};
	$self->{$KEY_CSS_SRC} = [];
	$self->{$KEY_CSS_CODE} = [];	
	$self->{$KEY_BODY_ATTR} = {};
	$self->{$KEY_REPLACE} = [];

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

	$clone->{$KEY_INITIAL_UI} = $self->{$KEY_INITIAL_UI};  # copy reference
	$clone->{$KEY_USER_COOKIE} = $self->{$KEY_USER_COOKIE}->clone();
	$clone->{$KEY_USER_INPUT} = $self->{$KEY_USER_INPUT}->clone();
	$clone->{$KEY_PERSIST_QUERY} = {%{$self->{$KEY_PERSIST_QUERY}}};
	$clone->{$KEY_REDIRECT_URL} = $self->{$KEY_REDIRECT_URL};

	$clone->{$KEY_MAIN_BODY} = [@{$self->{$KEY_MAIN_BODY}}];
	$clone->{$KEY_MAIN_HEAD} = [@{$self->{$KEY_MAIN_HEAD}}];
	$clone->{$KEY_TITLE} = $self->{$KEY_TITLE};
	$clone->{$KEY_AUTHOR} = $self->{$KEY_AUTHOR};
	$clone->{$KEY_META} = {%{$self->{$KEY_META}}};
	$clone->{$KEY_CSS_SRC} = [@{$self->{$KEY_CSS_SRC}}];
	$clone->{$KEY_CSS_CODE} = [@{$self->{$KEY_CSS_CODE}}];
	$clone->{$KEY_BODY_ATTR} = {%{$self->{$KEY_BODY_ATTR}}};
	$clone->{$KEY_REPLACE} = $self->replacements();  # makes copy
	
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

sub is_mod_perl {
	return( $ENV{'GATEWAY_INTERFACE'} =~ /^CGI-Perl/ );
}

######################################################################

sub user_cookie_str  { $_[0]->{$KEY_INITIAL_UI}->{$IKEY_COOKIE}   }
sub user_query_str   { $_[0]->{$KEY_INITIAL_UI}->{$IKEY_QUERY}    }
sub user_post_str    { $_[0]->{$KEY_INITIAL_UI}->{$IKEY_POST}     }
sub user_offline_str { $_[0]->{$KEY_INITIAL_UI}->{$IKEY_OFFLINE}  }
sub is_oversize_post { $_[0]->{$KEY_INITIAL_UI}->{$IKEY_OVERSIZE} }

######################################################################

sub request_method { $ENV{'REQUEST_METHOD'} || 'GET' }
sub content_length { $ENV{'CONTENT_LENGTH'} + 0 }

sub server_name { $ENV{'SERVER_NAME'} || 'localhost' }
sub virtual_host { $ENV{'HTTP_HOST'} || $_[0]->server_name() }
sub server_port { $ENV{'SERVER_PORT'} || 80 }
sub script_name {
	my $str = $ENV{'SCRIPT_NAME'};
	$str =~ tr/+/ /;
	$str =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
	return( $str );
}

sub http_referer {
	my $str = $ENV{'HTTP_REFERER'};
	$str =~ tr/+/ /;
	$str =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
	return( $str );
}

sub remote_addr { $ENV{'REMOTE_ADDR'} || '127.0.0.1' }
sub remote_host { $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'} || 
	'localhost' }
sub remote_user { $ENV{'AUTH_USER'} || $ENV{'LOGON_USER'} || 
	$ENV{'REMOTE_USER'} || $ENV{'HTTP_FROM'} || $ENV{'REMOTE_IDENT'} }
sub user_agent { $ENV{'HTTP_USER_AGENT'} }

######################################################################

sub base_url {
	my $self = shift( @_ );
	my $port = $self->server_port();
	return( 'http://'.$self->virtual_host().
		($port != 80 ? ":$port" : '').
		$self->script_name() );
}

######################################################################

sub self_url {
	my $self = shift( @_ );
	my $query = $self->user_query_str() || 
		$self->user_offline_str();
	return( $self->base_url().($query ? "?$query" : '') );
}

######################################################################

sub self_post {
	my $self = shift( @_ );
	my $button_label = shift( @_ ) || 'click here';
	my $url = $self->self_url();
	my $post_fields = $self->parse_url_encoded_queries( 0, 
		$self->user_post_str() )->to_html_encoded_hidden_fields();
	return( <<__endquote );
<FORM METHOD="post" ACTION="$url">
$post_fields
<INPUT TYPE="submit" NAME="" VALUE="$button_label">
</FORM>
__endquote
}

######################################################################

sub self_html {
	my $self = shift( @_ );
	my $visible_text = shift( @_ ) || 'here';
	return( $self->user_post_str() ? 
		$self->self_post( $visible_text ) : 
		'<A HREF="'.$self->self_url().'">'.$visible_text.'</A>' );
}

######################################################################

sub user_cookie {
	my $self = shift( @_ );
	if( ref( my $new_value = shift( @_ ) ) eq 'CGI::MultiValuedHash' ) {
		$self->{$KEY_USER_COOKIE} = $new_value->clone();
	}
	return( $self->{$KEY_USER_COOKIE} );
}

sub user_cookie_string {
	my $self = shift( @_ );
	return( $self->{$KEY_USER_COOKIE}->to_url_encoded_string('; ','&') );
}

sub user_cookie_param {
	my $self = shift( @_ );
	my $key = shift( @_ );
	if( @_ ) {
		return( $self->{$KEY_USER_COOKIE}->store( $key, @_ ) );
	} elsif( wantarray ) {
		return( @{$self->{$KEY_USER_COOKIE}->fetch( $key ) || []} );
	} else {
		return( $self->{$KEY_USER_COOKIE}->fetch_value( $key ) );
	}
}

######################################################################

sub user_input {
	my $self = shift( @_ );
	if( ref( my $new_value = shift( @_ ) ) eq 'CGI::MultiValuedHash' ) {
		$self->{$KEY_USER_INPUT} = $new_value->clone();
	}
	return( $self->{$KEY_USER_INPUT} );
}

sub user_input_string {
	my $self = shift( @_ );
	return( $self->{$KEY_USER_INPUT}->to_url_encoded_string() );
}

sub user_input_param {
	my $self = shift( @_ );
	my $key = shift( @_ );
	if( @_ ) {
		return( $self->{$KEY_USER_INPUT}->store( $key, @_ ) );
	} elsif( wantarray ) {
		return( @{$self->{$KEY_USER_INPUT}->fetch( $key ) || []} );
	} else {
		return( $self->{$KEY_USER_INPUT}->fetch_value( $key ) );
	}
}

sub user_input_keywords {
	my $self = shift( @_ );
	return( @{$self->{$KEY_USER_INPUT}->fetch( $UIP_KEYWORDS )} );
}

######################################################################

sub persistant_user_input_params {
	my $self = shift( @_ );
	if( ref( my $new_value = shift( @_ ) ) eq 'HASH' ) {
		$self->{$KEY_PERSIST_QUERY} = {%{$new_value}};
	}
	return( $self->{$KEY_PERSIST_QUERY} );
}

sub persistant_user_input_string {
	my $self = shift( @_ );
	return( $self->{$KEY_USER_INPUT}->fetch_mvh( 
		[keys %{$self->{$KEY_PERSIST_QUERY}}] 
		)->to_url_encoded_string() );
}

sub persistant_user_input_param {
	my $self = shift( @_ );
	my $key = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_PERSIST_QUERY}->{$key} = $new_value;
	}	
	return( $self->{$KEY_PERSIST_QUERY}->{$key} );
}

sub persistant_url {
	my $self = shift( @_ );
	my $persist_input_str = $self->persistant_user_input_string();
	return( $self->base_url().
		($persist_input_str ? "?$persist_input_str" : '') );
}

######################################################################

=head2 redirect_url([ VALUE ])

This method is an accessor for the "redirect url" scalar property of this object,
which it returns.  If VALUE is defined, this property is set to it.  If this
property is defined, then an http redirection header will be returned to the user 
instead of an ordinary web page.

=cut

######################################################################

sub redirect_url {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_REDIRECT_URL} = $new_value;
	}
	return( $self->{$KEY_REDIRECT_URL} );
}

######################################################################

sub get_http_headers {
	my $self = shift( @_ );

	require HTTP::Headers;
	my $http = HTTP::Headers->new();

	if( my $url = $self->{$KEY_REDIRECT_URL} ) {
		$http->header( 
			status => '301 Moved',  # used to be "302 Found"
			uri => $url,
			location => $url,
		);

	} else {
		$http->header( 
			status => '200 OK',
			content_type => 'text/html',
		);
	}

	return( $http );  # return HTTP headers object
}

######################################################################

sub send_headers_to_user {
	my ($self, $http) = @_;
	ref( $http ) eq 'HTTP::Headers' or $http = $self->get_http_headers();

	if( $self->is_mod_perl() ) {
		my $req = Apache->request();
		$http->scan( sub { $req->cgi_header_out( @_ ); } );			

	} else {
		my $endl = "\015\012";  # cr + lf
		print STDOUT $http->as_string( $endl ).$endl;
	}
}

sub send_content_to_user {
	my ($self, $content) = @_;
	defined( $content ) or $content = $self->content_as_string();
	print STDOUT $content;
}

sub send_to_user {
	my ($self, $http, $content) = @_;
	$self->send_headers_to_user( $http );
	$self->send_content_to_user( $content );
}

######################################################################

sub parse_url_encoded_cookies {
	my $self = shift( @_ );
	my $parsed = CGI::MultiValuedHash->new( shift( @_ ) );
	foreach my $string (@_) {
		$string =~ s/\s+/ /g;
		$parsed->from_url_encoded_string( $string, '; ', '&' );
	}
	return( $parsed );
}

sub parse_url_encoded_queries {
	my $self = shift( @_ );
	my $parsed = CGI::MultiValuedHash->new( shift( @_ ) );
	foreach my $string (@_) {
		$string =~ s/\s+/ /g;
		if( $string =~ /=/ ) {
			$parsed->from_url_encoded_string( $string );
		} else {
			$parsed->from_url_encoded_string( 
				"$UIP_KEYWORDS=$string", undef, ' ' );
		}
	}
	return( $parsed );
}

######################################################################
# This collects user input, and should only be called once by a program
# for the reason that multiple POST reads from STDIN can cause a hang 
# if the extra data isn't there.

sub get_initial_user_input {
	my $self = shift( @_ );
	my %iui = ();

	$iui{$IKEY_COOKIE} = $ENV{'HTTP_COOKIE'} || $ENV{'COOKIE'};
	
	if( $ENV{'REQUEST_METHOD'} =~ /^(GET|HEAD|POST)$/ ) {
		$iui{$IKEY_QUERY} = $ENV{'QUERY_STRING'};
		$iui{$IKEY_QUERY} ||= $ENV{'REDIRECT_QUERY_STRING'};
		
		if( $ENV{'CONTENT_LENGTH'} <= $MAX_CONTENT_LENGTH ) {
			read( STDIN, $iui{$IKEY_POST}, $ENV{'CONTENT_LENGTH'} );
			chomp( $iui{$IKEY_POST} );
		} else {  # post too large, error condition, post not taken
			$iui{$IKEY_OVERSIZE} = $MAX_CONTENT_LENGTH;
		}

	} elsif( $ARGV[0] ) {  # allow caller to save $ARGV[1..n] for themselves
		$iui{$IKEY_OFFLINE} = $ARGV[0];

	} else {
		print STDERR "offline mode: enter query string on standard input\n";
		print STDERR "it must be query-escaped and all one one line\n";
		$iui{$IKEY_OFFLINE} = <STDIN>;
		chomp( $iui{$IKEY_OFFLINE} );
	}

	return( \%iui );
}

######################################################################

=head2 body_content([ VALUES ])

This method is an accessor for the "body content" list property of this object,
which it returns.  This property is used literally to go between the "body" tag
pair of a new HTML document.  If VALUES is defined, this property is set to it,
and replaces any existing content.  VALUES can be any kind of valid list.  If the
first argument to this method is an ARRAY ref then that is taken as the entire
list; otherwise, all the arguments are taken as elements in a list.

=cut

######################################################################

sub body_content {
	my $self = shift( @_ );
	if( defined( $_[0] ) ) {
		$self->{$KEY_MAIN_BODY} = 
			(ref( $_[0] ) eq 'ARRAY') ? [@{$_[0]}] : [@_];
	}
	return( $self->{$KEY_MAIN_BODY} );  # returns ref
}

######################################################################

=head2 head_content([ VALUES ])

This method is an accessor for the "head content" list property of this object,
which it returns.  This property is used literally to go between the "head" tag
pair of a new HTML document.  If VALUES is defined, this property is set to it,
and replaces any existing content.  VALUES can be any kind of valid list.  If the
first argument to this method is an ARRAY ref then that is taken as the entire
list; otherwise, all the arguments are taken as elements in a list.

=cut

######################################################################

sub head_content {
	my $self = shift( @_ );
	if( defined( $_[0] ) ) {
		$self->{$KEY_MAIN_HEAD} = 
			(ref( $_[0] ) eq 'ARRAY') ? [@{$_[0]}] : [@_];
	}
	return( $self->{$KEY_MAIN_HEAD} );  # returns ref
}

######################################################################

=head2 title([ VALUE ])

This method is an accessor for the "title" scalar property of this object, which
it returns.  If VALUE is defined, this property is set to it.  This property is
used in the header of a new document to define its title.  Specifically, it goes
between a <TITLE></TITLE> tag pair.

=cut

######################################################################

sub title {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_TITLE} = $new_value;
	}
	return( $self->{$KEY_TITLE} );  # ret copy
}

######################################################################

=head2 author([ VALUE ])

This method is an accessor for the "author" scalar property of this object, which
it returns.  If VALUE is defined, this property is set to it.  This property is
used in the header of a new document to define its author.  Specifically, it is
used in a new '<LINK REV="made">' tag if defined.

=cut

######################################################################

sub author {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_AUTHOR} = $new_value;
	}
	return( $self->{$KEY_AUTHOR} );  # ret copy
}

######################################################################

=head2 meta([ KEY[, VALUE] ])

This method is an accessor for the "meta" hash property of this object, which it
returns.  If KEY is defined and it is a valid HASH ref, then this property is set
to it.  If KEY is defined but is not a HASH ref, then it is treated as a single
key into the hash of meta information, and the value associated with that hash
key is returned.  In the latter case, if VALUE is defined, then that new value is
assigned to the approprate meta key.  Meta information is used in the header of a
new document to say things like what the best keywords are for a search engine to
index this page under.  If this property is defined, then a '<META NAME="n"
VALUE="v">' tag would be made for each key/value pair.

=cut

######################################################################

sub meta {
	my $self = shift( @_ );
	if( ref( my $first = shift( @_ ) ) eq 'HASH' ) {
		$self->{$KEY_META} = {%{$first}};
	} elsif( defined( $first ) ) {
		if( defined( my $second = shift( @_ ) ) ) {
			$self->{$KEY_META}->{$first} = $second;
		}
		return( $self->{$KEY_META}->{$first} );
	}
	return( $self->{$KEY_META} );  # returns ref
}

######################################################################

=head2 style_sources([ VALUES ])

This method is an accessor for the "style sources" list property of this object,
which it returns.  If VALUES is defined, this property is set to it, and replaces
any existing content.  VALUES can be any kind of valid list.  If the first
argument to this method is an ARRAY ref then that is taken as the entire list;
otherwise, all the arguments are taken as elements in a list.  This property is
used in the header of a new document for linking in CSS definitions that are
contained in external documents; CSS is used by web browsers to describe how a
page is visually presented.  If this property is defined, then a '<LINK
REL="stylesheet" SRC="url">' tag would be made for each list element.

=cut

######################################################################

sub style_sources {
	my $self = shift( @_ );
	if( defined( $_[0] ) ) {
		$self->{$KEY_CSS_SRC} = 
			(ref( $_[0] ) eq 'ARRAY') ? [@{$_[0]}] : [@_];
	}
	return( $self->{$KEY_CSS_SRC} );  # returns ref
}

######################################################################

=head2 style_code([ VALUES ])

This method is an accessor for the "style code" list property of this object,
which it returns.  If VALUES is defined, this property is set to it, and replaces
any existing content.  VALUES can be any kind of valid list.  If the first
argument to this method is an ARRAY ref then that is taken as the entire list;
otherwise, all the arguments are taken as elements in a list.  This property is
used in the header of a new document for embedding CSS definitions in that
document; CSS is used by web browsers to describe how a page is visually
presented.  If this property is defined, then a "<STYLE><!-- code --></STYLE>"
multi-line tag is made for them.

=cut

######################################################################

sub style_code {
	my $self = shift( @_ );
	if( defined( $_[0] ) ) {
		$self->{$KEY_CSS_CODE} = 
			(ref( $_[0] ) eq 'ARRAY') ? [@{$_[0]}] : [@_];
	}
	return( $self->{$KEY_CSS_CODE} );  # returns ref
}

######################################################################

=head2 body_attributes([ KEY[, VALUE] ])

This method is an accessor for the "body attributes" hash property of this
object, which it returns.  If KEY is defined and it is a valid HASH ref, then
this property is set to it.  If KEY is defined but is not a HASH ref, then it is
treated as a single key into the hash of body attributes, and the value
associated with that hash key is returned.  In the latter case, if VALUE is
defined, then that new value is assigned to the approprate attribute key.  Body
attributes define such things as the background color the page should use, and
have names like 'bgcolor' and 'background'.  If this property is defined, then
the attribute keys and values go inside the opening <BODY> tag of a new document.

=cut

######################################################################

sub body_attributes {
	my $self = shift( @_ );
	if( ref( my $first = shift( @_ ) ) eq 'HASH' ) {
		$self->{$KEY_BODY_ATTR} = {%{$first}};
	} elsif( defined( $first ) ) {
		if( defined( my $second = shift( @_ ) ) ) {
			$self->{$KEY_BODY_ATTR}->{$first} = $second;
		}
		return( $self->{$KEY_BODY_ATTR}->{$first} );
	}
	return( $self->{$KEY_BODY_ATTR} );  # returns ref
}

######################################################################

=head2 replacements([ VALUES ])

This method is an accessor for the "replacements" array-of-hashes property of
this object, which it returns.  If VALUES is defined, this property is set to it,
and replaces any existing content.  VALUES can be any kind of valid list whose
elements are hashes.  This property is used in implementing this class'
search-and-replace functionality.  Within each hash, the keys define tokens that
we search our content for and the values are what we replace occurances with. 
Replacements are priortized by having multiple hashes; the hashes that are
earlier in the "replacements" list are performed before those later in the list.

=cut

######################################################################

sub replacements {
	my $self = shift( @_ );
	if( defined( $_[0] ) ) {
		my @new_values = (ref($_[0]) eq 'ARRAY') ? @{$_[0]} : @_;
		my @new_list = ();
		foreach my $element (@new_values) {
			ref( $element ) eq 'HASH' or next;
			push( @new_list, {%{$element}} );
		}
		$self->{$KEY_REPLACE} = \@new_list;
	}
	return( [map { {%{$_}} } @{$self->{$KEY_REPLACE}}] );  # ret copy
}

######################################################################

=head2 body_append( VALUES )

This method appends new elements to the "body content" list property of this
object, and that entire property is returned.

=cut

######################################################################

sub body_append {
	my $self = shift( @_ );
	my $ra_values = (ref( $_[0] ) eq 'ARRAY') ? shift( @_ ) : \@_;
	push( @{$self->{$KEY_MAIN_BODY}}, @{$ra_values} );
	return( $self->{$KEY_MAIN_BODY} );  # returns ref
}

######################################################################

=head2 body_prepend( VALUES )

This method prepends new elements to the "body content" list property of this
object, and that entire property is returned.

=cut

######################################################################

sub body_prepend {
	my $self = shift( @_ );
	my $ra_values = (ref( $_[0] ) eq 'ARRAY') ? shift( @_ ) : \@_;
	unshift( @{$self->{$KEY_MAIN_BODY}}, @{$ra_values} );
	return( $self->{$KEY_MAIN_BODY} );  # returns ref
}

######################################################################

=head2 head_append( VALUES )

This method appends new elements to the "head content" list property of this
object, and that entire property is returned.

=cut

######################################################################

sub head_append {
	my $self = shift( @_ );
	my $ra_values = (ref( $_[0] ) eq 'ARRAY') ? shift( @_ ) : \@_;
	push( @{$self->{$KEY_MAIN_HEAD}}, @{$ra_values} );
	return( $self->{$KEY_MAIN_HEAD} );  # returns ref
}

######################################################################

=head2 head_prepend( VALUES )

This method prepends new elements to the "head content" list property of this
object, and that entire property is returned.

=cut

######################################################################

sub head_prepend {
	my $self = shift( @_ );
	my $ra_values = (ref( $_[0] ) eq 'ARRAY') ? shift( @_ ) : \@_;
	unshift( @{$self->{$KEY_MAIN_HEAD}}, @{$ra_values} );
	return( $self->{$KEY_MAIN_HEAD} );  # returns ref
}

######################################################################

=head2 add_earlier_replace( VALUE )

This method prepends a new hash, defined by VALUE, to the "replacements"
list-of-hashes property of this object such that keys and values in the new hash
are searched and replaced earlier than any existing ones.  Nothing is returned.

=cut

######################################################################

sub add_earlier_replace {
	my $self = shift( @_ );
	if( ref( my $new_value = shift( @_ ) ) eq 'HASH' ) {
		unshift( @{$self->{$KEY_REPLACE}}, {%{$new_value}} );
	}
}

######################################################################

=head2 add_later_replace( VALUE )

This method appends a new hash, defined by VALUE, to the "replacements"
list-of-hashes property of this object such that keys and values in the new hash
are searched and replaced later than any existing ones.  Nothing is returned.

=cut

######################################################################

sub add_later_replace {
	my $self = shift( @_ );
	if( ref( my $new_value = shift( @_ ) ) eq 'HASH' ) {
		push( @{$self->{$KEY_REPLACE}}, {%{$new_value}} );
	}
}

######################################################################

=head2 do_replacements()

This method performs a search-and-replace of the "body content" property as
defined by the "replacements" property of this object.  This method is always
called by to_string() prior to the latter assembling a web page.

=cut

######################################################################

sub do_replacements {
	my $self = shift( @_ );
	my $body = join( '', @{$self->{$KEY_MAIN_BODY}} );
	foreach my $rh_pairs (@{$self->{$KEY_REPLACE}}) {
		foreach my $find_val (keys %{$rh_pairs}) {
			my $replace_val = $rh_pairs->{$find_val};
			$body =~ s/$find_val/$replace_val/g;
		}
	}
	$self->{$KEY_MAIN_BODY} = [$body];
}

######################################################################

=head2 content_as_string()

This method returns a scalar containing the complete HTML page that this object
describes, that is, it returns the string representation of this object.  This 
consists of a prologue tag, a pair of "html" tags and everything in between.  
This method requires HTML::EasyTags to do the actual page assembly, and so the 
results are consistant with its abilities.

=cut

######################################################################

sub content_as_string {
	my $self = shift( @_ );

	$self->do_replacements();

	require HTML::EasyTags;
	my $html = HTML::EasyTags->new();

	my ($title,$author,$meta,$css_src,$css_code);

	$self->{$KEY_AUTHOR} and $author = 
		$html->link( rev => 'made', href => "mailto:$self->{$KEY_AUTHOR}" );

	%{$self->{$KEY_META}} and $meta = join( '', map { 
		$html->meta_group( name => $_, value => $self->{$KEY_META}->{$_} ) 
		} keys %{$self->{$KEY_META}} );

	@{$self->{$KEY_CSS_SRC}} and $css_src = $html->link_group( 
		rel => 'stylesheet', type => 'text/css', href => $self->{$KEY_CSS_SRC} );

	@{$self->{$KEY_CSS_CODE}} and $css_code = 
		$html->style( $html->comment_tag( $self->{$KEY_CSS_CODE} ) );

	return( join( '', 
		$html->start_html(
			$self->{$KEY_TITLE},
			[ $author, $meta, $css_src, $css_code, @{$self->{$KEY_MAIN_HEAD}} ], 
			$self->{$KEY_BODY_ATTR}, 
		), 
		@{$self->{$KEY_MAIN_BODY}},
		$html->end_html(),
	) );
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

perl(1), mod_perl, CGI::WPM::Base, CGI::MultiValuedHash, HTML::EasyTags, 
HTTP::Headers, Apache.

=cut
