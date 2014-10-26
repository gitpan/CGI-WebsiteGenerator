=head1 NAME

CGI::WPM::PageMaker - Perl module that maintains and assembles the components of a 
new HTML 4 page, with CSS, and also provides search and replace capabilities.

=cut

######################################################################

package CGI::WPM::PageMaker;
require 5.004;

# Copyright (c) 1999-2001, Darren R. Duncan. All rights reserved. This module is
# free software; you can redistribute it and/or modify it under the same terms as
# Perl itself.  However, I do request that this copyright information remain
# attached to the file.  If you modify this module and redistribute a changed
# version then please attach a note listing the modifications.

use strict;
use vars qw($VERSION);
$VERSION = '1.02';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	HTML::EasyTags 1.0301  # required in content_as_string() method only

=head1 SYNOPSIS

	use CGI::WPM::PageMaker;

	my $webpage = CGI::WPM::PageMaker->new();

	$webpage->title( "What Is To Tell" );
	$webpage->author( "Mine Own Self" );
	$webpage->meta( { keywords => "hot spicy salty" } );
	$webpage->style_sources( "mypage.css" );
	$webpage->style_code( "H1 { align: center; }" );

	$webpage->replacements( {
		__url_one__ => (localtime())[6] == 0 ? "one.html" : "two.html",
		__url_two__ => (localtime())[6] == 0 ? "three.html" : "four.html",
	} );

	$webpage->body_content( <<__endquote );
	<H1>Good Reading</H1>
	<P>Greetings visitors, you must wonder why I called you here.
	Well you shall find out soon enough, but not from me.</P>
	__endquote

	if( (localtime())[6] == 0 ) {
		$webpage->body_append( <<__endquote );
	<P>Sorry, I have just been informed that we can't help you today,
	as the knowledge-bringers are not in attendance.  You will
	have to come back another time.</P>
	__endquote
	} else {
		$webpage->body_append( <<__endquote );
	<P>That's right, not from me, not in a million years.</P>
	__endquote
	}

	$webpage->body_append( <<__endquote );
	<P>[ click <A HREF="__url_one__">here</A> | 
	or <A HREF="__url_two__">here</A> ]</P>
	__endquote

	print STDOUT $webpage->content_as_string();

=head1 DESCRIPTION

This Perl 5 object class implements a simple data structure that makes it easy to
build up an HTML web page one piece at a time.  In its simplest concept, this
structure is an ordered list of content that would go between the "body" tags in
the document, and it is easy to either append or prepend content to a page.

Building on that concept, this class can also generate a complete HTML page with
one method call to content_as_string(), attaching the appropriate headers and
footers to the content of the page.  For more customization, this class also
stores a list of content that goes in the HTML document's "head" section.  As
well, it remembers attributes for a page such as "title", "author", various
"meta" information, and style sheets (linked or embedded).

The class HTML::EasyTags is required by content_as_string() to do the actual 
page assembly, and so the style of HTML formatting produced by the classes are 
consistant.  In addition, the capabilities of HTML::EasyTags define what kinds 
of special treatment we can provide for the content of the HTML HEAD section.
If you do not use this method then CGI::WPM::PageMaker requires no other modules.

Additional features include global search-and-replace in the body of multiple
tokens, which can be defined ahead of time and performed later.  Tokens can be
priortized such that the replacements are done in a specified order, rather than
the order they are defined; this is useful when one replacement yields a token
that another replacement must handle.

Future versions of this class will expand to handle an entire frameset document,
but that was omitted now for simplicity.

=head1 OUTPUT FROM SYNOPSIS PROGRAM

	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">
	<HTML>
	<HEAD>
	<TITLE>What Is To Tell</TITLE>
	<LINK REV="made" HREF="mailto:Mine Own Self">
	<META NAME="keywords" VALUE="hot spicy salty">
	<LINK TYPE="text/css" REL="stylesheet" HREF="mypage.css">
	<STYLE>
	<!-- H1 { align: center; } --></STYLE>
	</HEAD>
	<BODY><H1>Good Reading</H1>
	<P>Greetings visitors, you must wonder why I called you here.
	Well you shall find out soon enough, but not from me.</P>
	<P>Sorry, I have just been informed that we can't help you today,
	as the knowledge-bringers are not in attendance.  You will
	have to come back another time.</P>
	<P>[ click <A HREF="one.html">here</A> | 
	or <A HREF="three.html">here</A> ]</P>

	</BODY>
	</HTML>

=cut

######################################################################

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

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 FUNCTIONS AND METHODS

=head2 new()

This function creates a new CGI::WPM::PageMaker object and returns it.  This
page is empty by default.

=cut

######################################################################

sub new {
	my $class = shift( @_ );
	my $self = bless( {}, ref($class) || $class );
	$self->initialize( @_ );
	return( $self );
}

######################################################################

=head2 initialize()

This method is used by B<new()> to set the initial properties of an object,
that it creates.  All page attributes are wiped clean, resulting in an empty
page.

=cut

######################################################################

sub initialize {
	my $self = shift( @_ );
	$self->{$KEY_MAIN_BODY} = [];
	$self->{$KEY_MAIN_HEAD} = [];
	$self->{$KEY_TITLE} = undef;
	$self->{$KEY_AUTHOR} = undef;
	$self->{$KEY_META} = {};
	$self->{$KEY_CSS_SRC} = [];
	$self->{$KEY_CSS_CODE} = [];	
	$self->{$KEY_BODY_ATTR} = {};
	$self->{$KEY_REPLACE} = [];
}

######################################################################

=head2 clone([ CLONE ])

This method initializes a new object to have all of the same properties of the
current object and returns it.  This new object can be provided in the optional
argument CLONE (if CLONE is an object of the same class as the current object);
otherwise, a brand new object of the current class is used.  Only object 
properties recognized by CGI::WPM::PageMaker are set in the clone; other properties 
are not changed.

=cut

######################################################################

sub clone {
	my ($self, $clone, @args) = @_;
	ref($clone) eq ref($self) or $clone = bless( {}, ref($self) );

	$clone->{$KEY_MAIN_BODY} = [@{$self->{$KEY_MAIN_BODY}}];
	$clone->{$KEY_MAIN_HEAD} = [@{$self->{$KEY_MAIN_HEAD}}];
	$clone->{$KEY_TITLE} = $self->{$KEY_TITLE};
	$clone->{$KEY_AUTHOR} = $self->{$KEY_AUTHOR};
	$clone->{$KEY_META} = {%{$self->{$KEY_META}}};
	$clone->{$KEY_CSS_SRC} = [@{$self->{$KEY_CSS_SRC}}];
	$clone->{$KEY_CSS_CODE} = [@{$self->{$KEY_CSS_CODE}}];
	$clone->{$KEY_BODY_ATTR} = {%{$self->{$KEY_BODY_ATTR}}};
	$clone->{$KEY_REPLACE} = $self->replacements();  # makes copy

	return( $clone );
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
module to use in any of your own code then please send me the URL. Also, if you
make modifications to the module because it doesn't work the way you need, please
send me a copy so that I can roll desirable changes into the main release.

Address comments, suggestions, and bug reports to B<perl@DarrenDuncan.net>.

=head1 SEE ALSO

perl(1), HTML::EasyTags, CGI::WPM::Globals.

=cut
