=head1 NAME

CGI::WPM::GuestBook - Perl module that is a subclass of CGI::WPM::Base and
implements a complete guest book with unlimited questions that also e-mails 
submissions to the website owner.

=cut

######################################################################

package CGI::WPM::GuestBook;
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

	Fcntl
	Symbol
	Net::SMTP 2.15 (earlier versions may work)

=head2 Nonstandard Modules

	CGI::WPM::Globals 0.35
	CGI::WPM::Base 0.34
	CGI::MultiValuedHash 1.06
	HTML::FormTemplate 1.05

=cut

######################################################################

use Fcntl qw(:DEFAULT :flock);
use Symbol;
use CGI::WPM::Globals 0.35;
use CGI::WPM::Base 0.34;
@ISA = qw(CGI::WPM::Base);
use CGI::MultiValuedHash 1.06;
use HTML::FormTemplate 1.05;

######################################################################

=head1 SYNOPSIS

=head2 Shortest Complete GuestBook Program -- Uses Default Question

	my %CONFIG = (
		fn_messages => 'guestbook_messages.txt',  # file in SequentialFile format
	);

	require CGI::WPM::Globals;
	my $globals = CGI::WPM::Globals->new( "/path/to/site/files" );  # msgs in here
	
	$globals->site_title( 'Sample Web Site' );  # use this in e-mail subjects
	$globals->site_owner_name( 'Darren Duncan' );  # send messages to him
	$globals->site_owner_email( 'darren@sampleweb.net' );  # send messages here

	require CGI::WPM::GuestBook;
	$globals->move_site_prefs( \%CONFIG );
	CGI::WPM::GuestBook->execute( $globals );

	$globals->send_to_user();

=head2 Use Custom Questions Defined Here

	my %CONFIG = (
		fn_messages => 'guestbook_messages.txt',  # file in SequentialFile format
		custom_fd => 1,
		field_defn => [
			{
				visible_title => "What's your age?",
				type => 'textfield',
				name => 'name',
				is_required => 1,
				validation_rule => '\d',
				error_message => 'You must enter a number.',
			}, {
				visible_title => "What's the combination?",
				type => 'checkbox_group',
				name => 'words',
				'values' => ['eenie', 'meenie', 'minie', 'moe'],
				default => ['eenie', 'minie'],
				labels => [qw( This That And Another )],
			}, {
				visible_title => "Who do you love?",
				type => 'textfield',
				name => 'name',
			}, {
				visible_title => "What's your favorite colour?",
				type => 'popup_menu',
				name => 'color',
				'values' => ['red', 'green', 'blue', 'chartreuse'],
			},
		],
	);

=head2 Use Custom Questions Defined In Perl File

	my %CONFIG = (
		fn_messages => 'guestbook_messages.txt',  # file in SequentialFile format
		custom_fd => 1,
		field_defn => 'guestbook_questions.txt',  # do Perl code to make array ref
	);

=head2 Use Custom Questions Defined In SequentialFile File

	my %CONFIG = (
		fn_messages => 'guestbook_messages.txt',  # file in SequentialFile format
		custom_fd => 1,
		field_defn => 'guestbook_questions.txt',  # file in SequentialFile format
		fd_in_seqf => 1,
	);

=head2 Customize Subject Of Your Emails

	my %CONFIG = (
		fn_messages => 'guestbook_messages.txt',
		email_subj => 'Your Visitor Has Left A Message',
	);

=head2 Customize Webpage Intro Text

	my %CONFIG = (
		fn_messages => 'guestbook_messages.txt',
		msg_new_title => 'Leave A Message',  # custom title for new messages
		msg_new_head => <<__endquote,   # custom heading for new messages
	<H1>Leave A Message</H1>
	<P>Please leave a message after the beep.  Answer the questions as faithfully
	and truthfully as you can, as we have a lie detector set up and any false 
	answers will be met with spam.</P>
	__endquote
		msg_list_title => 'Previous Reflections',  # custom title when reading
		msg_list_head => <<__endquote,   # custom heading for reading
	<H1>Wise Words That You Never Wrote</H1>
	<P>Here are the messages that previous visitors wrote.  Please stay awhile 
	and soak in the goodness.  You never know what you don't read.</P>
	__endquote
	);

=head1 DESCRIPTION

I<This POD is coming when I get the time to write it.>

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 PUBLIC FUNCTIONS AND METHODS

This module inherits its entire public interface from CGI::WPM::Base.  Please see 
the POD for that module so you know how to call this one.

=head1 PREFERENCES HANDLED BY THIS MODULE

I<This POD is coming when I get the time to write it.>

	custom_fd   # if true, we use a custom list of 
		# questions in the form; otherwise, we simply have a "message" field.
	field_defn  # instruc for how to make form fields
		# If array ref, this is taken literally as list of definitions.
		# Otherwise, this is name of a file containing the definitions.
	fd_in_seqf  # if true, above file is of the 
		# format that CGI::WPM::SequentialFile handles; else it is Perl code

	fn_messages  # file messages go in, if filed

	email_subj  # if set, use when sending e-mails

	msg_new_title  # custom title for new messages
	msg_new_head   # custom heading for new messages

	msg_list_title  # custom title when reading
	msg_list_head   # custom heading for reading

=cut

######################################################################

# Names of properties for objects of this class are declared here:
my $KEY_SITE_GLOBALS = 'site_globals';  # hold global site values

# Keys for items in site page preferences:
my $PKEY_CUSTOM_FD  = 'custom_fd';  # if true, we use a custom list of 
	# questions in the form; otherwise, we simply have a "message" field.
my $PKEY_FIELD_DEFN = 'field_defn';  # instruc for how to make form fields
	# If array ref, this is taken literally as list of definitions.
	# Otherwise, this is name of a file containing the definitions.
my $PKEY_FD_IN_SEQF = 'fd_in_seqf';  # if true, above file is of the 
	# format that CGI::WPM::SequentialFile handles; else it is Perl code
my $PKEY_FN_MESSAGES = 'fn_messages';  # file messages go in, if filed
my $PKEY_EMAIL_SUBJ = 'email_subj';  # if set, use when sending e-mails
my $PKEY_MSG_NEW_TITLE = 'msg_new_title'; # custom title for new messages
my $PKEY_MSG_NEW_HEAD  = 'msg_new_head'; # custom heading for new messages
my $PKEY_MSG_LIST_TITLE = 'msg_list_title'; # custom title when reading
my $PKEY_MSG_LIST_HEAD  = 'msg_list_head'; # custom heading for reading

# Names of the fields in our html form:
my $FFN_NAMEREAL = 'namereal';  # user's real name
my $FFN_EMAIL    = 'email';     # user's e-mail address
my $FFN_WANTCOPY = 'wantcopy';  # true if sender wants a copy

# This is where the user's message goes, by default.
my @DEF_FORM_QUESTIONS = ( {
	visible_title => "Your Message",
	type => 'textarea',
	name => 'message',
	rows => 5,
	columns => 50,
	is_required => 1,
	error_message => 'You must enter a message.',
} );

# Extra fields in guest book log file
my $LFN_SUBMIT_DATE   = 'submit_date';
my $LFN_SUBMIT_DOMAIN = 'submit_domain';

# Constant values used in this class go here:
my $EMPTY_FIELD_ECHO_STRING = '(no answer)';
my $VRP_SIGN = 'sign';  # in this sub path is the book signing page
	# if no sub path is chosen, we view guest book by default

######################################################################
# This is provided so CGI::WPM::Base->dispatch_by_user() can call it.

sub _dispatch_by_user {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};

	SWITCH: {
		my $ra_field_defs = $self->get_field_definitions();
		if( $globals->get_error() ) {
			$self->no_questions_error();
			last SWITCH;
		}

		my $form = HTML::FormTemplate->new();
		$form->form_submit_url( $globals->self_url() );
		$form->field_definitions( $ra_field_defs );

		unless( $globals->current_user_vrp_element() eq $VRP_SIGN ) {
			$self->read_guest_book( $form );
			last SWITCH;
		}

		$form->user_input( $globals->user_input() 
			)->trim_bounding_whitespace();  # user_input() returns ref

		if( $form->new_form() ) {  # if we're called first time
			$self->new_message( $form );
			last SWITCH;
		}

		if( $form->validate_form_input() ) {  # if there were errors
			$self->invalid_input( $form );
			last SWITCH;
		}
		
		$self->send_mail_to_me( $form ) or last SWITCH;
		
		$self->sign_guest_book( $form ) or last SWITCH;

		$self->mail_me_and_sign_guest_ok( $form );
		
		if( $globals->user_input_param( $FFN_WANTCOPY ) eq 'on' ) {
			$self->send_mail_to_writer( $form );
		}
	}
}

######################################################################

sub get_field_definitions {
	my $self = shift( @_ );
	my @field_definitions = ();

	push( @field_definitions, 
		{
			visible_title => "Your Name",
			type => 'textfield',
			name => $FFN_NAMEREAL,
			size => 30,
			is_required => 1,
			error_message => 'You must enter your name.',
			exclude_in_echo => 1,
		}, {
			visible_title => "Your E-mail",
			type => 'textfield',
			name => $FFN_EMAIL,
			size => 30,
			is_required => 1,
			validation_rule => '\S\@\S',
			help_message => 'E-mails are in the form "user@domain".',
			error_message => 'You must enter your e-mail.',
			exclude_in_echo => 1,
		}, {
			visible_title => "Keep A Copy",
			type => 'checkbox',
			name => $FFN_WANTCOPY,
			nolabel => 1,
			help_message => "If checked, a copy of this message is e-mailed to you.",
			exclude_in_echo => 1,
		}, 
	);

	push( @field_definitions, @{$self->get_question_field_defs()} );

	push( @field_definitions, 
		{
			type => 'submit', 
			label => 'Post',
		}, {
			type => 'reset', 
			label => 'Clear',
			keep_with_prev => 1,
		},
	);

	return( \@field_definitions );
}

######################################################################

sub get_question_field_defs {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();
	
	# check if we are using default or custom questions
	unless( $rh_prefs->{$PKEY_CUSTOM_FD} ) {
		return( \@DEF_FORM_QUESTIONS );  # using default
	}
	
	my $field_defn = $rh_prefs->{$PKEY_FIELD_DEFN};
	
	# check if we have actual custom questions or filename to them
	if( ref($field_defn) eq 'ARRAY' ) {
		return( $field_defn );  # using actual
	}
	
	my $filepath = $globals->phys_filename_string( $field_defn );

	# check if question file is executable Perl or not
	unless( $rh_prefs->{$PKEY_FD_IN_SEQF} ) {  # it is Perl
		my $ra_field_list = do $filepath;
		unless( ref( $ra_field_list ) eq 'ARRAY' ) {
			$globals->add_error( "no valid array ref in '$field_defn'" );
			return( [] );
		}
		return( $ra_field_list );
	}
	
	# we will now get questions using CGI::WPM::SequentialFile
	my $ra_field_list = $self->_fetch_all_records( $filepath );
	ref( $ra_field_list ) eq 'ARRAY' or $ra_field_list = [];
	return( $ra_field_list );
}

######################################################################

sub no_questions_error {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->title( "Error Starting GuestBook" );

	$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>I'm sorry, but an error has occurred while trying to start 
the Guest Book.  We are missing critical settings information 
that is required to operate.  Specifically, we don't know what 
questions we are supposed to ask you.  Here are some details about 
what caused this problem:</P>

<P>@{[$globals->get_error()]}</P>

@{[$self->_get_amendment_message()]}
__endquote
}

######################################################################

sub read_guest_book {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $sign_gb_url = $globals->persistant_vrp_url( $VRP_SIGN );

	my $filename = $globals->site_pref( $PKEY_FN_MESSAGES );
	my $filepath = $globals->phys_filename_string( $filename );
	my @message_list = $self->_fetch_all_records( $filepath );

	if( my $err_msg = $globals->get_error() ) {
		$globals->title( "Error Reading GuestBook Postings" );

		$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>I'm sorry, but an error has occurred while trying to read the 
existing guest book messages from the log file, meaning that I can't 
show you any.</P>

<P>details: $err_msg</P>

@{[$self->_get_amendment_message()]}
__endquote

		return( 0 );
	}

	unless( @message_list ) {
		$globals->title( "Empty Guest Book" );

		$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>The guest book currently has no messages in it, as either none 
were successfully posted or they were deleted since then.  You can 
still <A HREF="$sign_gb_url">sign</A> it yourself, however.</P>
__endquote

		return( 1 );
	}

	my @message_html = ();
	
	foreach my $message (reverse @message_list) {
		$form->user_input( $message );
		my $name_real = $message->fetch_value( $FFN_NAMEREAL );
		my $submit_date = $message->fetch_value( $LFN_SUBMIT_DATE );
		push( @message_html, "<H3>From $name_real at $submit_date:</H3>" );
		push( @message_html, 
			$form->make_html_input_echo( 1, 1, $EMPTY_FIELD_ECHO_STRING ) );
		push( @message_html, "\n<HR>" );
	}
	pop( @message_html );  # get rid of trailing <HR>
	
	$globals->body_content( \@message_html );		
	
	$globals->body_prepend( <<__endquote );
<P>You may also <A HREF="$sign_gb_url">sign</A> 
this guest book yourself, if you wish.</P>
__endquote
	$globals->body_append( <<__endquote );
<P>You may also <A HREF="$sign_gb_url">sign</A> 
this guest book yourself, if you wish.</P>
__endquote

	$globals->title( $globals->site_pref( $PKEY_MSG_LIST_TITLE ) || 
		"Guest Book Messages" );

	$globals->body_prepend( 
		$globals->site_pref( $PKEY_MSG_LIST_HEAD ) || <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>Messages are ordered from newest to oldest.  
__endquote

	return( 1 );
}

######################################################################

sub new_message {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->title( $globals->site_pref( $PKEY_MSG_NEW_TITLE ) || 
		"Sign the Guest Book" );

	$globals->body_content( 
		$globals->site_pref( $PKEY_MSG_NEW_HEAD ) || <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>This form is provided as an easy way for you to give feedback 
concerning this web site, and at the same time, let everyone else 
know what you think.</P>
__endquote

	$globals->body_append( <<__endquote );
<P>The fields indicated with a '@{[$form->required_field_marker()]}' 
are required.</P>

@{$form->make_html_input_form( 1, 1 )}

<P>It may take from 1 to 30 seconds to process this form, so please be 
patient and don't click Send multiple times.  A confirmation message 
will appear if everything worked.</P>
__endquote
}

######################################################################

sub invalid_input {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->title( "Information Missing" );

	$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>Your submission could not be added to the guest book because some 
of the fields were not correctly filled in, which are indicated with a 
'@{[$form->bad_input_marker()]}'.  Fields with a 
'@{[$form->required_field_marker()]}' are required and can not be left 
empty.  Please make sure you have entered your name and e-mail address 
correctly, and then try sending it again.</P>

@{$form->make_html_input_form( 1, 1 )}

<P>It may take from 1 to 30 seconds to process this form, so please be 
patient and don't click Send multiple times.  A confirmation message 
will appear if everything worked.</P>
__endquote
}

######################################################################

sub send_mail_to_me {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	my $err_msg = $self->_send_email_message(
		$globals->site_owner_name(),
		$globals->site_owner_email(),
		$globals->user_input_param( $FFN_NAMEREAL ),
		$globals->user_input_param( $FFN_EMAIL ),
		$globals->site_pref( $PKEY_EMAIL_SUBJ ) || 
			$globals->site_title().' -- GuestBook Message',
		$form->make_text_input_echo( 0, $EMPTY_FIELD_ECHO_STRING ),
		<<__endquote.
It is the result of a form submission from a site visitor, 
"@{[$globals->user_input_param( $FFN_NAMEREAL )]}" <@{[$globals->user_input_param( $FFN_EMAIL )]}>.
From: @{[$globals->remote_addr()]} @{[$globals->remote_host()]}.
__endquote
		($globals->user_input_param( $FFN_WANTCOPY ) ? 
		"The visitor also requested a copy be sent to them.\n" : 
		"The visitor did not request a copy be sent to them.\n"),
	);

	if( $err_msg ) {
		$globals->add_error( $err_msg );
	
		$globals->title( "Error Sending Mail" );

		$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>I'm sorry, but an error has occurred while trying to e-mail your 
message to me.  It also hasn't been added to the guest book.  As a 
result, no one will see it.</P>

<P>This problem can occur if you enter a nonexistant or unreachable 
e-mail address into the e-mail field, in which case, please enter a 
working e-mail address and try clicking 'Send' again.  You can check 
if that is the problem by checking the following error string:</P>

<P>$err_msg</P>

@{[$self->_get_amendment_message()]}

@{$form->make_html_input_form( 1, 1 )}

<P>It may take from 1 to 30 seconds to process this form, so please be 
patient and don't click Send multiple times.  A confirmation message 
will appear if everything worked.</P>
__endquote

		return( 0 );
	}
	
	return( 1 );
}

######################################################################

sub sign_guest_book {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	my $new_posting = $globals->user_input()->clone();
	$new_posting->store( $LFN_SUBMIT_DATE, $self->_today_date_utc() );
	$new_posting->store( $LFN_SUBMIT_DOMAIN, 
		$globals->remote_addr().':'.$globals->remote_host() );

	my $filename = $globals->site_pref( $PKEY_FN_MESSAGES );
	my $filepath = $globals->phys_filename_string( $filename );
	$self->_append_new_records( $filepath, $new_posting );

	if( my $err_msg = $globals->get_error() ) {
		$globals->add_error( $err_msg );
	
		$globals->title( "Error Writing to Guest Book" );

		$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>I'm sorry, but an error has occurred while trying to write your 
message into the guest book.  As a result it will not appear when
the guest book is viewed by others.  However, the message was
e-mailed to me.</P>

<P>details: $err_msg</P>

@{[$self->_get_amendment_message()]}

@{$form->make_html_input_form( 1, 1 )}

<P>It may take from 1 to 30 seconds to process this form, so please be 
patient and don't click Send multiple times.  A confirmation message 
will appear if everything worked.</P>
__endquote

		return( 0 );
	}
	
	return( 1 );
}

######################################################################

sub mail_me_and_sign_guest_ok {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->title( "Your Message Has Been Added" );

	$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>Your message has been added to this guest book, and a copy was 
e-mailed to me as well.  This is what the copy e-mailed to me said:</P>

<P><STRONG>To:</STRONG> 
@{[$globals->site_owner_name()]}
<BR><STRONG>From:</STRONG> 
@{[$globals->user_input_param( $FFN_NAMEREAL )]} 
&lt;@{[$globals->user_input_param( $FFN_EMAIL )]}&gt;
<BR><STRONG>Subject:</STRONG> 
@{[$globals->site_pref( $PKEY_EMAIL_SUBJ ) || 
	$globals->site_title().' -- GuestBook Message']}</P>

@{[$form->make_html_input_echo( 1, 1, $EMPTY_FIELD_ECHO_STRING )]}
__endquote
}

######################################################################

sub send_mail_to_writer {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	my $err_msg = $self->_send_email_message(
		$globals->user_input_param( $FFN_NAMEREAL ),
		$globals->user_input_param( $FFN_EMAIL ),
		$globals->site_owner_name(),
		$globals->site_owner_email(),
		$globals->site_pref( $PKEY_EMAIL_SUBJ ) || 
			$globals->site_title().' -- GuestBook Message',
		$form->make_text_input_echo( 0, $EMPTY_FIELD_ECHO_STRING ),
		<<__endquote,
It is the result of a form submission from a site visitor, 
"@{[$globals->user_input_param( $FFN_NAMEREAL )]}" <@{[$globals->user_input_param( $FFN_EMAIL )]}>.
From: @{[$globals->remote_addr()]} @{[$globals->remote_host()]}.
__endquote
	);

	if( $err_msg ) {
		$globals->add_error( $err_msg );
		$globals->body_append( <<__endquote );
<P>However, something went wrong when trying to send you a copy:
$err_msg.</P>
__endquote

	} else {
		$globals->body_append( <<__endquote );
<P>Also, a copy was successfully sent to you at 
'@{[$globals->user_input_param( $FFN_EMAIL )]}'.</P>
__endquote
	}
}

######################################################################

sub _fetch_all_records {
	my $self = shift( @_ );
	my $file_path = shift( @_ );
	
	my $fh = gensym;
	
	$self->_open_and_lock( $fh, $file_path, 0 ) or return( undef );

	seek( $fh, 0, 0 ) or do {
		$self->_make_filesystem_error( "seek start of", $file_path );
		return( undef );
	};

	my $ra_record_list = CGI::MultiValuedHash->batch_from_file( $fh, 1 ) or do {
		$self->_make_filesystem_error( "read record from", $file_path );
		return( undef );
	};

	$self->_unlock_and_close( $fh, $file_path ) or return( undef );

	return( wantarray ? @{$ra_record_list} : $ra_record_list );
}

######################################################################

sub _append_new_records {
	my $self = shift( @_ );
	my $file_path = shift( @_ );
	my $ra_record_list = (ref( $_[0] ) eq 'ARRAY') ? $_[0] : [@_];
	
	my $fh = gensym;
	
	$self->_open_and_lock( $fh, $file_path, 1 ) or return( undef );

	seek( $fh, 0, 2 ) or do {
		$self->_make_filesystem_error( "seek end of", $file_path );
		return( undef );
	};

	CGI::MultiValuedHash->batch_to_file( $fh, $ra_record_list ) or do {
		$self->_make_filesystem_error( "write record to", $file_path );
		return( undef );
	};

	$self->_unlock_and_close( $fh, $file_path ) or return( undef );

	return( 1 );
}

######################################################################

sub _open_and_lock {
	my ($self, $fh, $file_path, $read_and_write) = @_;
	
	my $flags = $read_and_write ? O_RDWR|O_CREAT : O_RDONLY|O_CREAT;
	my $perms = 0666;

	sysopen( $fh, $file_path, $flags, $perms ) or do {
		$self->_make_filesystem_error( "open", $file_path );
		return( undef );
	};

	flock( $fh, $read_and_write ? LOCK_EX : LOCK_SH ) or do {
		$self->_make_filesystem_error( "lock", $file_path );
		return( undef );
	};

	return( 1 );
}

######################################################################

sub _unlock_and_close {
	my ($self, $fh, $file_path) = @_;
	
	flock( $fh, LOCK_UN ) or do {
		$self->_make_filesystem_error( "unlock", $file_path );
		return( undef );
	};

	close( $fh ) or do {
		$self->_make_filesystem_error( "close", $file_path );
		return( undef );
	};

	return( 1 );
}

######################################################################

sub _make_filesystem_error {
	my ($self, $unique_part, $file_path) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};
	$globals->add_error( "can't $unique_part data file '$file_path': $!" );
}

######################################################################

sub _send_email_message {
	my ($self, $to_name, $to_email, $from_name, $from_email, 
		$subject, $body, $body_head_addition) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	my $EMAIL_HEADER_STRIP_PATTERN = '[,<>()"\'\n]';  #for names and addys
	$to_name    =~ s/$EMAIL_HEADER_STRIP_PATTERN//g;
	$to_email   =~ s/$EMAIL_HEADER_STRIP_PATTERN//g;
	$from_name  =~ s/$EMAIL_HEADER_STRIP_PATTERN//g;
	$from_email =~ s/$EMAIL_HEADER_STRIP_PATTERN//g;
	$globals->is_debug() and $subject .= " -- debug";
	
	my $body_header = <<__endquote.
--------------------------------------------------
This e-mail was sent at @{[$self->_today_date_utc()]} 
by the web site "@{[$globals->site_title()]}", 
which is located at "@{[$globals->base_url()]}".
__endquote
	$body_head_addition.
	($globals->is_debug() ? "Debugging is currently turned on.\n" : 
	'').<<__endquote;
--------------------------------------------------
__endquote

	my $body_footer = <<__endquote;


--------------------------------------------------
END OF MESSAGE
__endquote
	
	my $host = $globals->smtp_host();
	my $timeout = $globals->smtp_timeout();
	my $error_msg = '';

	TRY: {
		my $smtp;

		eval { require Net::SMTP; };
		if( $@ ) {
			$error_msg = "can't open program module 'Net::SMTP'";
			last TRY;
		}
	
		unless( $smtp = Net::SMTP->new( $host, Timeout => $timeout ) ) {
			$error_msg = "can't connect to smtp host: $host";
			last TRY;
		}

		unless( $smtp->verify( $from_email ) ) {
			$error_msg = "invalid address: @{[$smtp->message()]}";
			last TRY;
		}

		unless( $smtp->verify( $to_email ) ) {
			$error_msg = "invalid address: @{[$smtp->message()]}";
			last TRY;
		}

		unless( $smtp->mail( "$from_name <$from_email>" ) ) {
			$error_msg = "from: @{[$smtp->message()]}";
			last TRY;
		}

		unless( $smtp->to( "$to_name <$to_email>" ) ) {
			$error_msg = "to: @{[$smtp->message()]}";
			last TRY;
		}

		$smtp->data( <<__endquote );
From: $from_name <$from_email>
To: $to_name <$to_email>
Subject: $subject
Content-Type: text/plain; charset=us-ascii

$body_header
$body
$body_footer
__endquote

		$smtp->quit();
	}
	
	return( $error_msg );
}

######################################################################

sub _today_date_utc {
	my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(time);
	$year += 1900;  # year counts from 1900 AD otherwise
	$mon += 1;      # ensure January is 1, not 0
	my @parts = ($year, $mon, $mday, $hour, $min, $sec);
	return( sprintf( "%4.4d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d UTC", @parts ) );
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

perl(1), CGI::WPM::Base, CGI::WPM::Globals, HTML::FormTemplate, 
CGI::MultiValuedHash, Net::SMTP, Fcntl, Symbol.

=cut
