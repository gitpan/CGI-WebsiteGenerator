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

# Copyright (c) 1999-2000, Darren R. Duncan. All rights reserved. This module is
# free software; you can redistribute it and/or modify it under the same terms as
# Perl itself.  However, I do request that this copyright information remain
# attached to the file.  If you modify this module and redistribute a changed
# version then please attach a note listing the modifications.

use strict;
use vars qw($VERSION);
$VERSION = '0.31';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	CGI::WPM::Globals 0.3

=cut

######################################################################

use CGI::WPM::Globals 0.3;

######################################################################

=head1 SYNOPSIS

I<This POD is coming when I get the time to write it.>

=head1 DESCRIPTION

I<This POD is coming when I get the time to write it.>

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using indirect notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.

=head1 PUBLIC FUNCTIONS AND METHODS

I<This POD is coming when I get the time to write it.>

	execute( GLOBALS ) - calls new(), then dispatch_by_user(), then finalize()
	
	-- or --
	
	new( GLOBALS )
	initialize( GLOBALS )
	dispatch_by_user()
	dispatch_by_admin()
	finalize() - replaces the depreciated shim finalize_page_content()

=head1 PREFERENCES HANDLED BY THIS MODULE

I<This POD is coming when I get the time to write it.>

	amend_msg  # personalized html appears on error page

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
	if( $self->{$KEY_SITE_GLOBALS}->get_error() ) {  # prefs not open
		$self->_set_to_init_error_page();
		return( 0 );
	}
	return( $self->_dispatch_by_user( @_ ) );
}

# subclass should have their own of these
sub _dispatch_by_user {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->title( 'Web Page For Users' );

	$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>This web page has been generated by CGI::WPM::Base, which is 
copyright (c) 1999-2000, Darren R. Duncan.  This Perl Class 
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
	if( $self->{$KEY_SITE_GLOBALS}->get_error() ) {  # prefs not open
		$self->_set_to_init_error_page();
		return( 0 );
	}
	return( $self->_dispatch_by_admin( @_ ) );
}

# subclass should have their own of these, if needed
sub _dispatch_by_admin {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->title( 'Web Page For Administrators' );

	$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>This web page has been generated by CGI::WPM::Base, which is 
copyright (c) 1999-2000, Darren R. Duncan.  This Perl Class 
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

Copyright (c) 1999-2000, Darren R. Duncan. All rights reserved. This module is
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

perl(1).

=cut
