=head1 NAME

CGI::WPM::MailForm - Perl module that is a subclass of CGI::WPM::Base and
implements an e-mail submission form with unlimited questions.

=cut

######################################################################

package CGI::WPM::MailForm;
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
	HTML::FormMaker
	CGI::HashOfArrays 1.01
	CGI::SequentialFile (optional)

=cut

######################################################################

use CGI::WPM::Base;
@ISA = qw(CGI::WPM::Base);
use HTML::FormMaker;

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

	custom_fd   # if true, we use a custom list of 
		# questions in the form; otherwise, we simply have a "message" field.
	field_defn  # instruc for how to make form fields
		# If array ref, this is taken literally as list of definitions.
		# Otherwise, this is name of a file containing the definitions.
	fd_in_seqf  # if true, above file is of the 
		# format that CGI::SequentialFile handles; else it is Perl code

	email_subj  # if set, use when sending e-mails

	msg_new_title  # custom title for new messages
	msg_new_head   # custom heading for new messages

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
	# format that CGI::SequentialFile handles; else it is Perl code
my $PKEY_EMAIL_SUBJ = 'email_subj';  # if set, use when sending e-mails
my $PKEY_MSG_NEW_TITLE = 'msg_new_title'; # custom title for new messages
my $PKEY_MSG_NEW_HEAD  = 'msg_new_head'; # custom heading for new messages

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

# Constant values used in this class go here:
my $EMPTY_FIELD_ECHO_STRING = '(no answer)';

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

		my $form = HTML::FormMaker->new();
		$form->form_submit_url( $globals->self_url() );
		$form->field_definitions( $ra_field_defs );

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
		
		$self->mail_me_ok( $form );
		
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
			label => 'Send',
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
	
	# we will now get questions using CGI::SequentialFile
	eval { require CGI::SequentialFile; };
	if( $@ ) {
		$globals->add_error( 
			"can't open program module 'CGI::SequentialFile'" );
		return( [] );
	}
	my $field_defin_file = CGI::SequentialFile->new( $filepath );
	my $ra_field_list = $field_defin_file->fetch_all_records( 1 );
	ref( $ra_field_list ) eq 'ARRAY' or $ra_field_list = [];
	$globals->add_error( $field_defin_file->is_error() );
	return( $ra_field_list );
}

######################################################################

sub no_questions_error {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->title( "Error Starting MailForm" );

	$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>I'm sorry, but an error has occurred while trying to start 
the Mail Form.  We are missing critical settings information 
that is required to operate.  Specifically, we don't know what 
questions we are supposed to ask you.  Here are some details about 
what caused this problem:</P>

<P>@{[$globals->get_error()]}</P>

@{[$self->_get_amendment_message()]}
__endquote
}

######################################################################

sub new_message {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->title( $globals->site_pref( $PKEY_MSG_NEW_TITLE ) || 
		"Send Me An E-mail" );

	$globals->body_content( 
		$globals->site_pref( $PKEY_MSG_NEW_HEAD ) || <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>This form is provided as an easy way for you to send me a private 
e-mail message, when you wish to contact me and/or give me your 
thoughts on this site.  This is also a good forum to report any bugs 
you have discovered, so I can fix them as soon as possible.</P>
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

<P>Your message could not be sent because some of the fields were not
correctly filled in, which are indicated with a 
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

	my $err_msg = $globals->send_email_message(
		$globals->site_owner_name(),
		$globals->site_owner_email(),
		$globals->user_input_param( $FFN_NAMEREAL ),
		$globals->user_input_param( $FFN_EMAIL ),
		$globals->site_pref( $PKEY_EMAIL_SUBJ ) || 
			$globals->site_title().' -- Private Mail Message',
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
message to me.  As a result I will not see it.</P>

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

sub mail_me_ok {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->title( "Your Message Has Been Sent" );

	$globals->body_content( <<__endquote );
<H2 ALIGN="center">@{[$globals->title()]}</H2>

<P>This is what the message said:</P>

<P><STRONG>To:</STRONG> 
@{[$globals->site_owner_name()]}
<BR><STRONG>From:</STRONG> 
@{[$globals->user_input_param( $FFN_NAMEREAL )]} 
&lt;@{[$globals->user_input_param( $FFN_EMAIL )]}&gt;
<BR><STRONG>Subject:</STRONG> 
@{[$globals->site_pref( $PKEY_EMAIL_SUBJ ) || 
	$globals->site_title().' -- Private Mail Message']}</P>

@{[$form->make_html_input_echo( 1, 1, $EMPTY_FIELD_ECHO_STRING )]}
__endquote
}

######################################################################

sub send_mail_to_writer {
	my ($self, $form) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	my $err_msg = $globals->send_email_message(
		$globals->user_input_param( $FFN_NAMEREAL ),
		$globals->user_input_param( $FFN_EMAIL ),
		$globals->site_owner_name(),
		$globals->site_owner_email(),
		$globals->site_pref( $PKEY_EMAIL_SUBJ ) || 
			$globals->site_title().' -- Private Mail Message',
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
