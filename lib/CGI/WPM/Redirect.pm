=head1 NAME

CGI::WPM::Redirect - Perl module that is a subclass of CGI::WPM::Base and issues 
an HTTP redirection header.

=cut

######################################################################

package CGI::WPM::Redirect;
require 5.004;

# Copyright (c) 1999-2000, Darren R. Duncan. All rights reserved. This module is
# free software; you can redistribute it and/or modify it under the same terms as
# Perl itself.  However, I do request that this copyright information remain
# attached to the file.  If you modify this module and redistribute a changed
# version then please attach a note listing the modifications.

use strict;
use vars qw($VERSION @ISA);
$VERSION = '0.32';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	CGI::WPM::Base 0.3
	CGI::WPM::Globals 0.3

=cut

######################################################################

use CGI::WPM::Base 0.3;
@ISA = qw(CGI::WPM::Base);

######################################################################

=head1 SYNOPSIS

=head2 Redirect To A Custom Url

	require CGI::WPM::Globals;
	my $globals = CGI::WPM::Globals->new();
	
	require CGI::WPM::Redirect;
	$globals->move_site_prefs( {} );  # looks at query parameter "url"
	CGI::WPM::Redirect->execute( $globals );
	
	$globals->send_to_user();  # sends a 301 Moved header

=head2 Always Redirect To Same Url

	$globals->move_site_prefs( {url => 'http://www.samplesitenew.net'} );

=head1 DESCRIPTION

I<This POD is coming when I get the time to write it.>

This module sets the redirect_url() property of the WebUserIO object that 
Globals inherits from, and the latter does the actual work; you could do this 
directly if you wished.  This Redirect module will spit out an ordinary HTML 
page if it doesn't know what url to forward to.  It is intended to be used in 
larger web sites that want to track outgoing visitors with the same program 
that makes the site's pages.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using indirect notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.

=head1 PUBLIC FUNCTIONS AND METHODS

This module inherits its entire public interface from CGI::WPM::Base.  Please see 
the POD for that module so you know how to call this one.

=head1 PREFERENCES HANDLED BY THIS MODULE

I<This POD is coming when I get the time to write it.>

	url  # preferences can say where we redirect to

=cut

######################################################################

# Names of properties for objects of parent class are declared here:
my $KEY_SITE_GLOBALS = 'site_globals';  # hold global site values

# Keys for items in site page preferences:
my $PKEY_EXPL_DEST_URL = 'url';  # our preferences may tell us where

# Constant values used by this class:
my $UIPN_DEST_URL = 'url';  # or look in the user input instead

######################################################################
# This is provided so CGI::WPM::Base->dispatch_by_user() can call it.

sub _dispatch_by_user {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $dest_url = $globals->site_pref( $PKEY_EXPL_DEST_URL ) || 
		$globals->user_input_param( $UIPN_DEST_URL );
	
	unless( $dest_url ) {
		$globals->title( 'No Url Provided' );

		$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>I'm sorry, but this redirection page requires either a site 
preference named "$PKEY_EXPL_DEST_URL", or a query parameter named 
"$UIPN_DEST_URL", whose value is an url.  No url was provided, so I 
can't redirect you to it.  If you got this error while clicking 
on one of the links on this website, then the problem is likely 
on this end.  In the latter case...</P>

@{[$self->_get_amendment_message()]}
__endquote

		return( 1 );
	}

	$globals->redirect_url( $dest_url );
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

perl(1), CGI::WPM::Base, CGI::WPM::Globals, CGI::WebUserIO.

=cut
