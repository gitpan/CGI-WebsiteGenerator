=head1 NAME

CGI::WPM::MultiPage - Perl module that is a subclass of CGI::WPM::Base and
resolves navigation for one level in the web site page hierarchy from a parent
node to its children, encapsulates and returns its childrens' returned web page
components, and can make a navigation bar to child pages.

=cut

######################################################################

package CGI::WPM::MultiPage;
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

	CGI::WPM::Base 0.31
	CGI::WPM::Globals 0.3

=cut

######################################################################

use CGI::WPM::Base 0.31;
@ISA = qw(CGI::WPM::Base);

######################################################################

=head1 SYNOPSIS

	require CGI::WPM::Globals;  # to hold our input, output, preferences
	my $globals = CGI::WPM::Globals->new( "/path/to/site/files" );  # get input

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

	$globals->add_later_replace( {  # do some token substitutions
		__mailme_url__ => "__vrp_id__=/mailme",
		__external_id__ => "__vrp_id__=/external&url",
	} );

	$globals->add_later_replace( {  # more token substitutions in static pages
		__vrp_id__ => $globals->persistant_vrp_url(),
	} );

	$globals->send_to_user();  # send output page now that everything's ready

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
		menu_items => [
			{
				menu_name => 'Front Door',
				menu_path => '',
				is_active => 1,
			}, {
				menu_name => 'Welcome to SampleWeb',
				menu_path => 'intro',
				is_active => 1,
			}, {
				menu_name => "What's New",
				menu_path => 'whatsnew',
				is_active => 1,
			}, 1, {
				menu_name => 'Story Timelines',
				menu_path => 'timelines',
				is_active => 1,
			}, {
				menu_name => 'Issue Indexes',
				menu_path => 'indexes',
				is_active => 1,
			}, {
				menu_name => 'Works Cited',
				menu_path => 'cited',
				is_active => 1,
			}, {
				menu_name => 'Preview Database',
				menu_path => 'dbprev',
				is_active => 0,
			}, 1, {
				menu_name => 'Send Me E-mail',
				menu_path => 'mailme',
				is_active => 1,
			}, {
				menu_name => 'Guest Book',
				menu_path => 'guestbook',
				is_active => 1,
			}, 1, {
				menu_name => 'External Links',
				menu_path => 'links',
				is_active => 1,
			}, {
				menu_name => 'Webrings',
				menu_path => 'webrings',
				is_active => 1,
			},
		],
		menu_cols => 4,
	#	menu_colwid => 100,
		menu_showdiv => 0,
	#	menu_bgcolor => '#ddeeff',
		page_showdiv => 1,
	};

=head1 DESCRIPTION

I<This POD is coming when I get the time to write it.>

Generated page menus are entirely optional, so if you don't like the format 
you can roll your own.  Due to advances in release 0.3, you can nest as many 
levels of MultiPage as you wish, and they will work as you expect.  Each 
"child" of MultiPage is called in the same means as if that page were the only 
one in the whole program; each has its own handler WPM module, its own config 
data, and optionally its own srp subdirectory.  

Subdirectories are all relative, so having '' means the current directory, 
'something' is a level down, '..' is a level up, '../another' is a level 
sideways, 'one/more/time' is 3 levels down.  However, any relative subdir 
beginning with '/' becomes absolute, where '/' corresponds to the site file 
root.  You can not go to parents of the site root.  Those are physical 
directories (site resource path), and the uri does not reflect them.  The uri 
does, however, reflect uri changes (virtual resource path).  

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using indirect notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.

=head1 PUBLIC FUNCTIONS AND METHODS

This module inherits its entire public interface from CGI::WPM::Base.  Please see 
the POD for that module so you know how to call this one.

=head1 PREFERENCES HANDLED BY THIS MODULE

I<This POD is coming when I get the time to write it.>

	vrp_handlers  # match wpm handler to a vrp
	def_handler   # if vrp undef, which handler?
	menu_items    # items in site menu, vrp for each
	menu_cols     # menu divided into n cols
	menu_colwid   # width of each col, in pixels
	menu_showdiv  # show dividers btwn menu groups?
	menu_bgcolor  # background for menu
	menu_showdiv  # show dividers btwn menu groups?
	page_showdiv  # do we use HRs to sep menu?

=head2 PROPERTIES OF ELEMENTS IN vrp_handlers HASH

	wpm_module  # wpm module making content
	wpm_subdir  # subdir holding wpm support files
	wpm_prefs   # prefs hash/fn we give to wpm mod

=head2 PROPERTIES OF ELEMENTS IN menu_items ARRAY

	menu_name  # visible name appearing in site menu
	menu_path  # vrp used in url for menu item
	is_active  # is menu item enabled or not?

=cut

######################################################################

# Names of properties for objects of this class are declared here:
my $KEY_SITE_GLOBALS = 'site_globals';  # hold global site values

# Keys for items in site global preferences:

# Keys for items in site page preferences:
my $PKEY_VRP_HANDLERS = 'vrp_handlers';  # match wpm handler to a vrp
my $PKEY_DEF_HANDLER  = 'def_handler';  # if vrp undef, which handler?
my $PKEY_MENU_ITEMS   = 'menu_items';  # items in site menu, vrp for each
my $PKEY_MENU_COLS    = 'menu_cols';  # menu divided into n cols
my $PKEY_MENU_COLWID  = 'menu_colwid';  # width of each col, in pixels
my $PKEY_MENU_SHOWDIV = 'menu_showdiv';  # show dividers btwn menu groups?
my $PKEY_MENU_BGCOLOR = 'menu_bgcolor';  # background for menu
my $PKEY_PAGE_SHOWDIV = 'page_showdiv';  # do we use HRs to sep menu?

# Keys for elements in $PKEY_VRP_HANDLERS hash:
my $HKEY_WPM_MODULE = 'wpm_module';  # wpm module making content
my $HKEY_WPM_SUBDIR = 'wpm_subdir';  # subdir holding wpm support files
my $HKEY_WPM_PREFS = 'wpm_prefs';  # prefs hash/fn we give to wpm mod

# Keys for elements in $PKEY_MENU_ITEMS array:
my $MKEY_MENU_NAME = 'menu_name';  # visible name appearing in site menu
my $MKEY_MENU_PATH = 'menu_path';  # vrp used in url for menu item
my $MKEY_IS_ACTIVE = 'is_active';  # is menu item enabled or not?

# Constant values used in this class go here:

######################################################################
# This is provided so CGI::WPM::Base->dispatch_by_user() can call it.

sub _dispatch_by_user {
	my $self = shift( @_ );

	$self->get_inner_wpm_content();  # puts in webpage of $globals

	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();

	if( $rh_prefs->{$PKEY_PAGE_SHOWDIV} ) {
		$globals->body_prepend( "\n<HR>\n" );
		$globals->body_append( "\n<HR>\n" );
	}

	if( ref( $rh_prefs->{$PKEY_MENU_ITEMS} ) eq 'ARRAY' ) {
		$self->attach_page_menu();
	}
}

######################################################################

sub get_inner_wpm_content {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();

	my $page_id = $globals->current_user_vrp_element();
	$page_id ||= $rh_prefs->{$PKEY_DEF_HANDLER};
	my $vrp_handler = $rh_prefs->{$PKEY_VRP_HANDLERS}->{$page_id};
	
	unless( ref( $vrp_handler ) eq 'HASH' ) {
		$globals->title( '404 Page Not Found' );

		$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>I'm sorry, but the page you requested, 
"@{[$globals->user_vrp_string()]}", doesn't seem to exist.  
If you manually typed that address into the browser, then it is either 
outdated or you misspelled it.  If you got this error while clicking 
on one of the links on this website, then the problem is likely 
on this end.  In the latter case...</P>

@{[$self->_get_amendment_message()]}
__endquote

		return( 1 );
	}
	
	my $wpm_mod_name = $vrp_handler->{$HKEY_WPM_MODULE};

	$globals->inc_user_vrp_level();
	$globals->move_current_vrp( $page_id );
	$globals->move_current_srp( $vrp_handler->{$HKEY_WPM_SUBDIR} );
	$globals->move_site_prefs( $vrp_handler->{$HKEY_WPM_PREFS} );

	eval {
		# "require $wpm_mod_name;" yields can't find module in @INC error
		eval "require $wpm_mod_name;"; if( $@ ) { die $@; }

		unless( $wpm_mod_name->isa( 'CGI::WPM::Base' ) ) {
			die "Error: $wpm_mod_name isn't a subclass of ".
				"CGI::WPM::Base, so I don't know how to use it\n";
		}

		my $wpm = $wpm_mod_name->new( $globals );

		$wpm->dispatch_by_user();

		$wpm->finalize();
	};

	$globals->restore_site_prefs();
	$globals->restore_last_srp();
	$globals->restore_last_vrp();
	$globals->dec_user_vrp_level();

	if( $@ ) {
		$globals->add_error( "can't use module '$wpm_mod_name': $@\n" );
	
		$globals->title( 'Error Getting Page' );

		$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>I'm sorry, but an error occurred while getting the requested
page.  We were unable to use the module that was supposed to 
generate the page content, named "$wpm_mod_name".</P>

@{[$self->_get_amendment_message()]}

<P>$@</P>
__endquote
	}
}

######################################################################

sub attach_page_menu {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	
	my $menu_table = $self->make_page_menu_table();

	$globals->body_prepend( [$menu_table] );
	$globals->body_append( [$menu_table] );
}

######################################################################

sub make_menu_items_html {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};	
	my $rh_prefs = $globals->site_prefs();
	my $ra_menu_items = $rh_prefs->{$PKEY_MENU_ITEMS};
	my @menu_html = ();
	
	foreach my $rh_curr_page (@{$ra_menu_items}) {
		if( ref( $rh_curr_page ) ne 'HASH' ) {
			$rh_prefs->{$PKEY_MENU_SHOWDIV} or next;
			push( @menu_html, undef );   # insert menu divider,
			next;                   
		}

		unless( $rh_curr_page->{$MKEY_IS_ACTIVE} ) {
			push( @menu_html, "$rh_curr_page->{$MKEY_MENU_NAME}" );
			next;
		}
		
		my $url = $globals->persistant_vrp_url( 
			$rh_curr_page->{$MKEY_MENU_PATH} );
		push( @menu_html, "<A HREF=\"$url\"".
			">$rh_curr_page->{$MKEY_MENU_NAME}</A>" );
	}
	
	return( @menu_html );
}

######################################################################
# This method currently isn't called by anything, but may be later.

sub make_page_menu_vert {
	my $self = shift( @_ );
	my @menu_items = $self->make_menu_items_html();
	my @menu_html = ();
	my $prev_item = undef;
	foreach my $curr_item (@menu_items) {
		push( @menu_html, 
			!defined( $curr_item ) ? "<HR>\n" : 
			defined( $prev_item ) ? "<BR>$curr_item\n" : 
			"$curr_item\n" );
		$prev_item = $curr_item;
	}
	return( '<P>'.join( '', @menu_html ).'</P>' );
}

######################################################################
# This method currently isn't called by anything, but may be later.

sub make_page_menu_horiz {
	my $self = shift( @_ );
	my @menu_items = $self->make_menu_items_html();
	my @menu_html = ();
	foreach my $curr_item (@menu_items) {
		defined( $curr_item ) or next;
		push( @menu_html, "$curr_item\n" );
	}
	return( '<P>'.join( ' | ', @menu_html ).'</P>' );
}

######################################################################

sub make_page_menu_table {
	my $self = shift( @_ );
	my $rh_prefs = $self->{$KEY_SITE_GLOBALS}->site_prefs();
	my @menu_items = $self->make_menu_items_html();
	
	my $length = scalar( @menu_items );
	my $max_cols = $rh_prefs->{$PKEY_MENU_COLS};
	$max_cols <= 1 and $max_cols = 1;
	my $max_rows = 
		int( $length / $max_cols ) + ($length % $max_cols ? 1 : 0);

	my $colwid = $rh_prefs->{$PKEY_MENU_COLWID};
	$colwid and $colwid = " WIDTH=\"$colwid\"";
	
	my $bgcolor = $rh_prefs->{$PKEY_MENU_BGCOLOR};
	$bgcolor and $bgcolor = " BGCOLOR=\"$bgcolor\"";
	
	my @table_lines = ();
	
	push( @table_lines, "<TABLE BORDER=0 CELLSPACING=0 ".
		"CELLPADDING=10 ALIGN=\"center\">\n<TR>\n" );
	
	foreach my $col_num (1..$max_cols) {
		my $prev_item = undef;
		my @cell_lines = ();
		my @cell_items = splice( @menu_items, 0, $max_rows ) or last;
		foreach my $curr_item (@cell_items) {
			push( @cell_lines, 
				!defined( $curr_item ) ? "<HR>\n" : 
				defined( $prev_item ) ? "<BR>$curr_item\n" : 
				"$curr_item\n" );
			$prev_item = $curr_item;
		}
		push( @table_lines,
			"<TD ALIGN=\"left\" VALIGN=\"top\"$bgcolor$colwid>\n",
			@cell_lines, "</TD>\n" );
	}
	
	push( @table_lines, "</TR>\n</TABLE>\n" );

	return( join( '', @table_lines ) );
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

perl(1), CGI::WPM::Base, CGI::WPM::Globals.

=cut
