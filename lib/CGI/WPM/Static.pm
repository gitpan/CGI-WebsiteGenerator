=head1 NAME

CGI::WPM::Static - Perl module that is a subclass of CGI::WPM::Base and displays
a static HTML page.

=cut

######################################################################

package CGI::WPM::Static;
require 5.004;

# Copyright (c) 1999-2000, Darren R. Duncan. All rights reserved. This module is
# free software; you can redistribute it and/or modify it under the same terms as
# Perl itself.  However, I do request that this copyright information remain
# attached to the file.  If you modify this module and redistribute a changed
# version then please attach a note listing the modifications.

use strict;
use vars qw($VERSION @ISA);
$VERSION = '0.3';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	CGI::WPM::Base
	CGI::WPM::Globals

=cut

######################################################################

use CGI::WPM::Base;
@ISA = qw(CGI::WPM::Base);

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

This module inherits its entire public interface from CGI::WPM::Base.  Please see 
the POD for that module so you know how to call this one.

=head1 PREFERENCES HANDLED BY THIS MODULE

I<This POD is coming when I get the time to write it.>

	filename  # name of file we will open
	is_text   # true if file is not html, but text
	
=cut

######################################################################

# Names of properties for objects of parent class are declared here:
my $KEY_SITE_GLOBALS = 'site_globals';  # hold global site values

# Keys for items in site page preferences:
my $PKEY_FILENAME = 'filename';  # name of file we will open
my $PKEY_IS_TEXT  = 'is_text';   # true if file is not html, but text

######################################################################
# This is provided so CGI::WPM::Base->dispatch_by_user() can call it.

sub _dispatch_by_user {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $filename = $globals->site_pref( $PKEY_FILENAME );
	my $physical_path = $globals->phys_filename_string( $filename );
	my $is_text = $globals->site_pref( $PKEY_IS_TEXT );

	SWITCH: {
		$globals->add_no_error();

		open( STATIC, "<$physical_path" ) or do {
			$globals->add_filesystem_error( $filename, "open" );
			last SWITCH;
		};
		local $/ = undef;
		defined( my $file_content = <STATIC> ) or do {
			$globals->add_filesystem_error( $filename, "read from" );
			last SWITCH;
		};
		close( STATIC ) or do {
			$globals->add_filesystem_error( $filename, "close" );
			last SWITCH;
		};
		
		if( $is_text ) {
			$file_content =~ s/&/&amp;/g;  # do some html escaping
			$file_content =~ s/\"/&quot;/g;
			$file_content =~ s/>/&gt;/g;
			$file_content =~ s/</&lt;/g;
		
			$globals->body_content( 
				[ "\n<PRE>\n", $file_content, "\n</PRE>\n" ] );
		
		} elsif( $file_content =~ m|<BODY[^>]*>(.*)</BODY>|si ) {
			$globals->body_content( $1 );
			if( $file_content =~ m|<TITLE>(.*)</TITLE>|si ) {
				$globals->title( $1 );
			}
		} else {
			$globals->body_content( $file_content );
		}	
	}

	if( $globals->get_error() ) {
		$globals->title( 'Error Opening Page' );
		$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>I'm sorry, but an error has occurred while trying to open 
the page you requested, which is in the file "$filename".</P>  

@{[$self->_get_amendment_message()]}

<P>Details: @{[$globals->get_error()]}</P>
__endquote
	}
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
