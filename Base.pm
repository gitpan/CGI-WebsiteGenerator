=head1 NAME

CGI::WPM::Base - Perl module that defines the API for subclasses, which are
miniature applications called "web page makers", and provides them with a
hierarchical environment that handles details for obtaining program settings,
resolving file system or web site contexts, obtaining user input, and sending new
web pages to the user.

=cut

######################################################################

package CGI::WPM::Base;
require 5.004;

# Copyright (c) 1999-2001, Darren R. Duncan. All rights reserved. This module is
# free software; you can redistribute it and/or modify it under the same terms as
# Perl itself.  However, I do request that this copyright information remain
# attached to the file.  If you modify this module and redistribute a changed
# version then please attach a note listing the modifications.

use strict;
use vars qw($VERSION);
$VERSION = '0.34';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	CGI::WPM::Globals 0.34

=cut

######################################################################

use CGI::WPM::Globals 0.34;

######################################################################

=head1 SYNOPSIS

=head2 How A Subclass Is Called

	require CGI::WPM::Globals;  # to hold our input, output, preferences
	my $globals = CGI::WPM::Globals->new( "/path/to/site/files" );  # get input
	
	$globals->site_title( 'Sample Web Site' );  # use this in e-mail subjects
	$globals->site_owner_name( 'Darren Duncan' );  # send messages to him
	$globals->site_owner_email( 'darren@sampleweb.net' );  # send messages here

	require HelloWorld;  # all content is made through here
	$globals->move_current_srp( 'content' );  # subdir holding content files
	$globals->move_site_prefs( {'text' => 'hey you'} );  # configuration details
	HelloWorld->execute( $globals );  # do all the work
	$globals->restore_site_prefs();  # rewind configuration context
	$globals->restore_last_srp();  # rewind subdir context

	$globals->send_to_user();  # send output now that everything's ready

=head2 A Simple Hello World Subclass

	package HelloWorld;
	require 5.004;

	use strict;
	use vars qw($VERSION @ISA);
	$VERSION = '0.01';

	use CGI::WPM::Base 0.3;
	@ISA = qw(CGI::WPM::Base);

	sub _dispatch_by_user {
		my $self = shift( @_ );
		my $globals = $self->{'site_globals'};

		$globals->title( $globals->site_title().' - Hello World' );
		$globals->body_content( <<__endquote );
	<H2 ALIGN="center">@{[$globals->title()]}</H2>

	<P>This module doesn't do anything interesting, but what the hey, 
	everyone has to do a "hello world" program sometime.</P>
	
	<P>Oh, and the main program says @{[$globals->site_pref( 'text' )]}.</P>
	
	<P>You can write to @{[$globals->site_owner_name()]} 
	at @{[$globals->site_owner_email()]}.</P>
	
	<P>Click <A HREF="@{[$globals->self_url()]}">here</A> to call me back.</P>
	__endquote
	}

	1;

=head1 DESCRIPTION

I<This POD is coming when I get the time to write it.>

The above module can be its own complete web site, or it can be one page on a 
larger site, it's up to you to decide.  Also, there can be multiple pages made 
by the same HelloWorld module, with their preferences differentiating them.
Any WPM module can call others in turn, and each call should be preceeded and 
followed by setting/rewinding the context for the inner module.  Each module can 
act like it is the only one in the system, whether that is true or not.  But 
follow proper programming protocols like only unwinding contexts you set, and 
vice-versa.  The Globals object does not enforce anything like that.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 PUBLIC FUNCTIONS AND METHODS

I<This POD is coming when I get the time to write it.>

	execute( GLOBALS ) - calls new(), then dispatch_by_user(), then finalize()
	
	-- or --
	
	new( GLOBALS )
	initialize( GLOBALS )
	dispatch_by_user()
	dispatch_by_admin()
	finalize() - replaces the depreciated shim finalize_page_content()

Note that the second approach is depreciated, and only execute() should be used.
In release 0.4 the second approach will not be available.

=head1 PREFERENCES HANDLED BY THIS MODULE

I<This POD is coming when I get the time to write it.>

	amend_msg  # personalized html appears on error page instead of subc action

	page_body    # if defined, no subclass is used and this literal used instead
	page_header  # content goes above our subclass's
	page_footer  # content goes below our subclass's
	page_title   # title for this document
	page_author  # author for this document
	page_meta    # meta tags for this document
	page_css_src   # stylesheet urls to link in
	page_css_code  # css code to embed in head
	page_body_attr # params to put in <BODY>
	page_replace   # replacements to perform

=head1 PRIVATE METHODS FOR OVERRIDING BY SUBCLASSES

I<This POD is coming when I get the time to write it.>

	_initialize()
	_dispatch_by_user()
	_dispatch_by_admin()
	_finalize()

=head1 PRIVATE METHODS FOR USE BY SUBCLASSES

I<This POD is coming when I get the time to write it.>

	_set_to_init_error_page()
	_get_amendment_message()

=cut

######################################################################

# Names of properties for objects of this class are declared here:
my $KEY_SITE_GLOBALS = 'site_globals';  # hold global site values

# Keys for items in site global preferences:
my $PKEY_AMEND_MSG = 'amend_msg';  # personalized html appears on error page

# Keys for items in site page preferences:
my $PKEY_PAGE_BODY = 'page_body';  # if defined, use literally *as* content

my $PKEY_PAGE_HEADER = 'page_header'; # content goes above our subclass's
my $PKEY_PAGE_FOOTER = 'page_footer'; # content goes below our subclass's
my $PKEY_PAGE_TITLE = 'page_title';  # title for this document
my $PKEY_PAGE_AUTHOR = 'page_author';  # author for this document
my $PKEY_PAGE_META = 'page_meta';  # meta tags for this document
my $PKEY_PAGE_CSS_SRC = 'page_css_src';  # stylesheet urls to link in
my $PKEY_PAGE_CSS_CODE = 'page_css_code';  # css code to embed in head
my $PKEY_PAGE_BODY_ATTR = 'page_body_attr';  # params to put in <BODY>
my $PKEY_PAGE_REPLACE = 'page_replace';  # replacements to perform

######################################################################
# This provides a simpler interface for the most common activity, which has 
# an ordinary web site visitor viewing a page.  Call it like this:
# "ClassName->execute( $globals );"

sub execute {
	my $self = shift( @_ )->new( @_ );
	$self->dispatch_by_user();
	$self->finalize();
	return( $self );
}

######################################################################

sub new {
	my $class = shift( @_ );
	my $self = bless( {}, ref($class) || $class );
	$self->initialize( @_ );
	return( $self );
}

######################################################################

sub initialize {
	my ($self, $globals) = @_;

	ref($globals) eq 'CGI::WPM::Globals' or 
		die "initializer is not a valid CGI::WPM::Globals object";

	%{$self} = (
		$KEY_SITE_GLOBALS => $globals,
	);

	$self->_initialize( @_ );
}

# subclass should have their own of these, if needed
sub _initialize {
}

######################################################################

sub dispatch_by_user {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};	
	if( $globals->get_error() ) {  # prefs not open
		$self->_set_to_init_error_page();
		return( 0 );
	}
	my $body = $globals->site_prefs()->{$PKEY_PAGE_BODY};
	return( defined( $body ) ? $globals->body_content( $body ) : 
		$self->_dispatch_by_user( @_ ) );
}

# subclass should have their own of these
sub _dispatch_by_user {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->title( 'Web Page For Users' );

	$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>This web page has been generated by CGI::WPM::Base, which is 
copyright (c) 1999-2001, Darren R. Duncan.  This Perl Class 
is intended to be subclassed before it is used.</P>

<P>You are reading this message because either no subclass is in use 
or that subclass hasn't declared the _dispatch_by_user() method, 
which is required to generate the web pages that normal visitors 
would see.</P>
__endquote
}

######################################################################

sub dispatch_by_admin {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};	
	if( $globals->get_error() ) {  # prefs not open
		$self->_set_to_init_error_page();
		return( 0 );
	}
	my $body = $globals->site_prefs()->{$PKEY_PAGE_BODY};
	return( defined( $body ) ? $globals->body_content( $body ) : 
		$self->_dispatch_by_admin( @_ ) );
}

# subclass should have their own of these, if needed
sub _dispatch_by_admin {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->title( 'Web Page For Administrators' );

	$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>This web page has been generated by CGI::WPM::Base, which is 
copyright (c) 1999-2001, Darren R. Duncan.  This Perl Class 
is intended to be subclassed before it is used.</P>

<P>You are reading this message because either no subclass is in use 
or that subclass hasn't declared the _dispatch_by_admin() method, 
which is required to generate the web pages that site administrators 
would use to administrate site content using their web browsers.</P>
__endquote
}

######################################################################

sub finalize {   # should be called after "dispatch" methods
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();
		# note that we don't see parent prefs here, only current level

	$globals->body_prepend( $rh_prefs->{$PKEY_PAGE_HEADER} );
	$globals->body_append( $rh_prefs->{$PKEY_PAGE_FOOTER} );

	$globals->title() or $globals->title( $rh_prefs->{$PKEY_PAGE_TITLE} );
	$globals->author() or $globals->author( $rh_prefs->{$PKEY_PAGE_AUTHOR} );
	
	if( ref( my $rh_meta = $rh_prefs->{$PKEY_PAGE_META} ) eq 'HASH' ) {
		@{$globals->meta()}{keys %{$rh_meta}} = values %{$rh_meta};
	}	

	if( defined( my $css_urls_pref = $rh_prefs->{$PKEY_PAGE_CSS_SRC} ) ) {
		push( @{$globals->style_sources()}, 
			ref($css_urls_pref) eq 'ARRAY' ? @{$css_urls_pref} : () );
	}
	if( defined( my $css_code_pref = $rh_prefs->{$PKEY_PAGE_CSS_CODE} ) ) {
		push( @{$globals->style_code()}, 
			ref($css_code_pref) eq 'ARRAY' ? @{$css_code_pref} : () );
	}

	if( ref(my $rh_body = $rh_prefs->{$PKEY_PAGE_BODY_ATTR}) eq 'HASH' ) {
		@{$globals->body_attributes()}{keys %{$rh_body}} = 
			values %{$rh_body};
	}	

	$globals->add_later_replace( $rh_prefs->{$PKEY_PAGE_REPLACE} );

	$self->_finalize();
}

# subclass should have their own of these, if needed
sub _finalize {
}

# this is a depreciated shim so that older code won't break right away
sub finalize_page_content {
	my $self = shift( @_ );
	return( $self->finalize( @_ ) );
}

######################################################################
# This is meant to be called after the global "is error" is set

sub _set_to_init_error_page {
	my $self = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->title( 'Error Initializing Page Maker' );

	$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>I'm sorry, but an error has occurred while trying to initialize 
a required program module, "@{[ref($self)]}".  The file that 
contains its preferences couldn't be opened.</P>  

@{[$self->_get_amendment_message()]}

<P>Details: @{[$globals->get_error()]}</P>
__endquote
}

######################################################################

sub _get_amendment_message {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	return( $globals->site_pref( $PKEY_AMEND_MSG ) || <<__endquote );
<P>This should be temporary, the result of a transient server problem
or a site update being performed at the moment.  Click 
@{[$globals->self_html('here')]} to automatically try again.  
If the problem persists, please try again later, or send an
@{[$globals->site_owner_email_html('e-mail')]}
message about the problem, so it can be fixed.</P>
__endquote
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

perl(1), CGI::WPM::Globals.

=cut
