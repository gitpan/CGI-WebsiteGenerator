=head1 NAME

CGI::WPM::Usage - Perl module that is a subclass of CGI::WPM::Base and tracks
site usage details, as well as e-mail backups of usage counts to the site owner.

=cut

######################################################################

package CGI::WPM::Usage;
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

	Net::SMTP 2.15 (earlier versions may work)

=head2 Nonstandard Modules

	CGI::WPM::Base 0.34
	CGI::WPM::Globals 0.34
	CGI::WPM::EventCountFile 1.04

=cut

######################################################################

use CGI::WPM::Base 0.34;
@ISA = qw(CGI::WPM::Base);
use CGI::WPM::EventCountFile 1.04;

######################################################################

=head1 SYNOPSIS

	require CGI::WPM::Globals;
	my $globals = CGI::WPM::Globals->new( "/path/to/site/files" );  # get input

	if( $globals->user_input_param( 'debugging' ) eq 'on' ) {
		$globals->is_debug( 1 );  # let us keep separate logs when debugging
	}

	$globals->site_title( 'Sample Web Site' );  # use this in e-mail subjects
	$globals->site_owner_name( 'Darren Duncan' );  # send reports to him
	$globals->site_owner_email( 'darren@sampleweb.net' );  # send reports here

	require CGI::WPM::Usage;
	$globals->move_current_srp( $globals->is_debug() ? 'usage_debug' : 'usage' );
	$globals->move_site_prefs( '../usage_prefs.pl' );  # configuration file
	CGI::WPM::Usage->execute( $globals );  # do all the work
	$globals->restore_site_prefs();
	$globals->restore_last_srp();

	$globals->send_to_user();  # send output

=head2 Content of Configuration File "usage_prefs.pl"

	my $rh_preferences = { 
		email_logs => 1,  # do we want to be sent daily reports?
		fn_dcm => 'date_counts_mailed.txt',  # our lock file to track mailings
		mailing => [  # keep different types of reports in own emails
			{
				filenames => 'env.txt',
				subject_unique => ' -- usage (env) to ',
			}, {
				filenames => 'site_vrp.txt',
				subject_unique => ' -- usage (page views) to ',
			}, {
				filenames => 'redirect_urls.txt',
				subject_unique => ' -- usage (external) to ',
			}, {
				filenames => [qw(
					ref_urls.txt ref_se_urls.txt 
					ref_se_keywords.txt ref_discards.txt
				)],
				subject_unique => ' -- usage (references) to ',
				erase_files => 1,  # start over listing each day
			},
		],
		env => {  # what misc info do we want to know (low value distrib)
			filename => 'env.txt',
			var_list => [qw(
				DOCUMENT_ROOT GATEWAY_INTERFACE HTTP_CONNECTION HTTP_HOST
				REQUEST_METHOD SCRIPT_FILENAME SCRIPT_NAME SERVER_ADMIN 
				SERVER_NAME SERVER_PORT SERVER_PROTOCOL SERVER_SOFTWARE
			)],
		},
		site => {  # which pages on our own site are viewed?
			filename => 'site_vrp.txt',
		},
		redirect => {  # which of our external links are followed?
			filename => 'redirect_urls.txt',
		},
		referrer => {  # what sites are referring to us?
			filename => 'ref_urls.txt',   # normal websites go here
			fn_search => 'ref_se_urls.txt',  # search engines go here
			fn_keywords => 'ref_se_keywords.txt',  # their keywords go here
			fn_discards => 'ref_discards.txt',  # uris we filter out
			site_urls => [qw(  # which urls we want to count as self-reference
				http://www.sampleweb.net
				http://sampleweb.net
				http://www.sampleweb.net/default.pl
				http://sampleweb.net/default.pl
				http://www.sampleweb.net:80
				http://sampleweb.net:80
				http://www.sampleweb.net:80/default.pl
				http://sampleweb.net:80/default.pl
			)],
			discards => [qw(  # filter uri's we want to ignore
				^(?!http://)
				deja
				mail
			)],
			use_def_engines => 1,  # use info on some engines that class holds
			search_engines => {  # match domain with query param holding keywords
				superfind => 'query',
				getitnow => 'qt',
				'gimme.com' => 'iwant',
			},
		},
	};

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

I<This POD is coming when I get the time to write it.  Meanwhile, the 
Synopsis uses the most important ones.  Most of them are optional.>

=cut

######################################################################

# Names of properties for objects of this class are declared here:
my $KEY_SITE_GLOBALS = 'site_globals';  # hold global site values

# Keys for items in site page preferences:

my $PKEY_TOKEN_TOTAL = 'token_total'; # token counts number of file updates
my $PKEY_TOKEN_NIL   = 'token_nil'; # token counts number of '' values
my $PKEY_EMAIL_LOGS  = 'email_logs'; # true if logs get emailed
my $PKEY_FN_DCM      = 'fn_dcm';  # filename for "date counts mailed" record
my $PKEY_MAILING     = 'mailing';  # array of hashes
my $PKEY_LOG_ENV      = 'env'; # misc env variables go in here
	# Generally only ENVs with a low distribution of values go here.
my $PKEY_LOG_SITE     = 'site'; # pages within this site (vrp) go in here
my $PKEY_LOG_REDIRECT = 'redirect'; # urls we redirect to go in here
my $PKEY_LOG_REFERRER  = 'referrer'; # urls that refer to us go in here
	# note that urls for common search engines are stored separately 
	# from those that aren't

# Keys for elements in $PKEY_MAILING hash:
my $MKEY_FILENAMES      = 'filenames'; # list of filenames to include in mailing
my $MKEY_ERASE_FILES    = 'erase_files'; # if true, then erase files afterwards
my $MKEY_SUBJECT_UNIQUE = 'subject_unique'; # unique part of e-mail subject
	# this text would go following site title and before today's date in subject

# Keys in common for $KEY_LOG_* hashes:
my $LKEY_FILENAME = 'filename';

# Keys used only in $KEY_LOG_ENV hash:
my $EKEY_VAR_LIST = 'var_list'; # name misc env variables to watch

# Keys used only in $KEY_LOG_SITE hash:
my $SKEY_TOKEN_REDIRECT = 'token_redirect';

# Keys used only in $KEY_LOG_REFERRER hash:
my $RKEY_FN_SEARCH       = 'fn_search'; # urls for ref common search engines
	# note that search engine query strings are removed here, go next
my $RKEY_FN_KEYWORDS     = 'fn_keywords'; # keywords used in sea eng ref url
	# note that only se are counted, normal site kw kept with their urls
my $RKEY_FN_DISCARDS     = 'fn_discards'; # urls such as news:// go only here
my $RKEY_TOKEN_REF_SELF  = 'token_ref_self'; # indicates referer was same site
my $RKEY_TOKEN_REF_OTHER = 'token_ref_other'; # ref not self but in other file
my $RKEY_SITE_URLS       = 'site_urls'; # list urls site is, no qs
	# This is useful, for example, to treat 'www' or prefixless versions 
	# of this site's url as being one and the same.  Include 'http://'.
	# Don't worry about case, as urls are automatically lowercased.
my $RKEY_DISCARDS        = 'discards'; # if ref url matches these, filter junk
my $RKEY_SEARCH_ENGINES  = 'search_engines'; # search engines and kw param names
my $RKEY_USE_DEF_ENGINES = 'use_def_engines'; # if true, use our own se list

# Constant values used in this class go here:

# This hash stores domain parts for common search engines in the keys, 
# and its values are names of query params that hold the keywords.
# They are all lowercased here for simplicity.  It's not complete, but I 
# learned these engines because they linked to my web sites.
my %DEF_SEARCH_ENGINE_TERMS = (  # match keys against domains proper only
	alltheweb => 'query', # AllTheWeb
	altavista => 'q',     # Altavista
	'aj.com' => 'ask',    # Ask Jeeves
	aol => 'query',       # America Online
	'ask.com' => 'ask',   # Ask Jeeves
	askjeeves => 'ask',   # Ask Jeeves
	'c4.com' => 'searchtext', # C4
	'cs.com' => 'sterm',  # CompuServe
	dmoz => 'search',     # Mozilla Open Directory
	dogpile => 'q',       # DogPile
	excite => 's',        # Excite
	google => 'q',        # Google
	'goto.com' => 'keywords', # GoTo.com, Inc
	'icq.com' => 'query', # ICQ
	infogrid => 'search', # InfoGrid
	intelliseek => 'queryterm', # "Infrastructure For Intelligent Portals"
	iwon => 'searchfor',  # I Won
	looksmart => 'key',   # LookSmart
	lycos => 'query',     # Lycos
	mamma => 'query',     # "Mother of Search Engines"
	metacrawler => 'general', # MetaCrawler
	msn => ['q','mt'],    # Microsoft
	nbci => 'keyword',    # NBCi
	netscape => 'search', # Netscape
	ninemsn => 'q',       # nine msn
	northernlight => 'qr', # Northern Light Search
	'search.com' => 'q',  # CNET
	'searchalot' => 'search', # SearchALot
	snap => 'keyword',    # Microsoft
	webcrawler => 'search', # Webcrawler
	yahoo => 'p',         # Yahoo
);

######################################################################
# This is provided so CGI::WPM::Base->dispatch_by_user() can call it.

sub _dispatch_by_user {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();

	$rh_prefs->{$PKEY_TOKEN_TOTAL} ||= '__total__';
	$rh_prefs->{$PKEY_TOKEN_NIL} ||= '__nil__';

	$self->email_and_reset_counts_if_new_day();
	
	$self->update_env_counts();
	$self->update_site_vrp_counts();
	$self->update_redirect_counts();
	$self->update_referrer_counts();
	
	# Note that we don't presently print hit counts to the webpage.
	# But that'll likely be added later, along with web usage reports.
}

######################################################################

sub email_and_reset_counts_if_new_day {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();

	$rh_prefs->{$PKEY_EMAIL_LOGS} or return( 1 );

	$globals->add_no_error();
	my $dcm_file = CGI::WPM::EventCountFile->new( 
		$globals->phys_filename_string( $rh_prefs->{$PKEY_FN_DCM} ), 1 );
	$dcm_file->open_and_lock( 1 ) or do {
		$globals->add_error( $dcm_file->is_error() );
		return( 0 );
	};
	$dcm_file->read_all_records();
	if( $dcm_file->key_was_incremented_today( 
			$rh_prefs->{$PKEY_TOKEN_TOTAL} ) ) {
		$dcm_file->unlock_and_close();
		return( 1 );
	}
	$dcm_file->key_increment( $rh_prefs->{$PKEY_TOKEN_TOTAL} );
	$dcm_file->write_all_records();
	$dcm_file->unlock_and_close();

	my $ra_mail_prefs = $rh_prefs->{$PKEY_MAILING};
	ref( $ra_mail_prefs ) eq 'ARRAY' or $ra_mail_prefs = [$ra_mail_prefs];

	foreach my $rh_mail_pref (@{$ra_mail_prefs}) {
		ref( $rh_mail_pref ) eq 'HASH' or next;

		my $ra_filenames = $rh_mail_pref->{$MKEY_FILENAMES} || [];
		ref( $ra_filenames ) eq 'ARRAY' or $ra_filenames = [$ra_filenames];
		my $erase_files = $rh_mail_pref->{$MKEY_ERASE_FILES};

		my @mail_body = ();

		foreach my $filename (@{$ra_filenames}) {
			$filename or next;
			my $count_file = CGI::WPM::EventCountFile->new( 
				$globals->phys_filename_string( $filename ), 1 );
			$count_file->open_and_lock( 1 ) or do {
				push( @mail_body, "\n\n".$count_file->is_error()."\n" );
				next;
			};
			$count_file->read_all_records();
			push( @mail_body, "\n\ncontent of '$filename':\n\n" );
			push( @mail_body, $count_file->get_sorted_file_content() );
			if( $erase_files ) {
				$count_file->delete_all_keys();
			} else {
				$count_file->set_all_day_counts_to_zero();
			}
			$count_file->write_all_records();
			$count_file->unlock_and_close();
		}

		my ($today_str) = ($globals->today_date_utc() =~ m/^(\S+)/ );
		my $subject_unique = $rh_mail_pref->{$MKEY_SUBJECT_UNIQUE};
		defined( $subject_unique) or $subject_unique = ' -- usage to ';

		my $err_msg = $self->_send_email_message(
			$globals->site_owner_name(),
			$globals->site_owner_email(),
			$globals->site_owner_name(),
			$globals->site_owner_email(),
			$globals->site_title().$subject_unique.$today_str,
			join( '', @mail_body ),
			<<__endquote,
This is a daily copy of the site usage count logs.
The first visitor activity on $today_str has just occurred.
__endquote
		);

		if( $err_msg ) {
			$globals->add_error( "can't e-mail usage counts: $err_msg" );
		}
	}
}

######################################################################

sub update_env_counts {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();
	
	my $rh_log_prefs = $rh_prefs->{$PKEY_LOG_ENV};
	ref( $rh_log_prefs ) eq 'HASH' or return( 0 );
	
	my $filename = $rh_log_prefs->{$LKEY_FILENAME} or return( 0 );
	my $ra_var_list = $rh_log_prefs->{$EKEY_VAR_LIST};
	ref( $ra_var_list ) eq 'ARRAY' or $ra_var_list = [$ra_var_list];
	
	# save miscellaneous low-distribution environment vars
	$self->update_one_count_file( $filename, 
		(map { "\$ENV{$_} = \"$ENV{$_}\"" } @{$ra_var_list}) );
}

######################################################################

sub update_site_vrp_counts {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();
	
	my $rh_log_prefs = $rh_prefs->{$PKEY_LOG_SITE};
	ref( $rh_log_prefs ) eq 'HASH' or return( 0 );
	
	my $filename = $rh_log_prefs->{$LKEY_FILENAME} or return( 0 );
	my $t_rd = $rh_log_prefs->{$SKEY_TOKEN_REDIRECT} || '__external_url__';
	
	# save which page within this site was hit
	$self->update_one_count_file( $filename, 
		$globals->user_vrp_string(), 
		$globals->redirect_url() ? $t_rd : () );
}

######################################################################

sub update_redirect_counts {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();
	
	my $rh_log_prefs = $rh_prefs->{$PKEY_LOG_REDIRECT};
	ref( $rh_log_prefs ) eq 'HASH' or return( 0 );
	
	my $filename = $rh_log_prefs->{$LKEY_FILENAME} or return( 0 );
	
	# save which url this site referred the visitor to, if any
	$self->update_one_count_file( $filename, $globals->redirect_url() );
}

######################################################################

sub update_referrer_counts {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();
	
	my $rh_log_prefs = $rh_prefs->{$PKEY_LOG_REFERRER};
	ref( $rh_log_prefs ) eq 'HASH' or return( 0 );
	
	my $fn_normal = $rh_log_prefs->{$LKEY_FILENAME};
	my $fn_search = $rh_log_prefs->{$RKEY_FN_SEARCH};
	my $fn_keywords = $rh_log_prefs->{$RKEY_FN_KEYWORDS};
	my $fn_discards = $rh_log_prefs->{$RKEY_FN_DISCARDS};
	
	my $t_rfs = $rh_log_prefs->{$RKEY_TOKEN_REF_SELF} || '__self_reference__';
	my $t_rfo = $rh_log_prefs->{$RKEY_TOKEN_REF_OTHER} || '__other_reference__';
	
	my $ra_site_urls = $rh_log_prefs->{$RKEY_SITE_URLS} || [];
	ref( $ra_site_urls ) eq 'ARRAY' or $ra_site_urls = [$ra_site_urls];
	unshift( @{$ra_site_urls}, $globals->base_url() );
	
	my $ra_discards = $rh_log_prefs->{$RKEY_DISCARDS} || [];
	ref( $ra_discards ) eq 'ARRAY' or $ra_discards = [$ra_discards];
	
	my $rh_engines = $rh_log_prefs->{$RKEY_SEARCH_ENGINES} || {};
	ref( $rh_engines ) eq 'HASH' or $rh_engines = ();
	if( $rh_log_prefs->{$RKEY_USE_DEF_ENGINES} ) {
		%{$rh_engines} = (%DEF_SEARCH_ENGINE_TERMS, %{$rh_engines});
	}
	
	# save which url had referred visitors to this site
	my (@ref_norm, @ref_sear, @ref_keyw, @ref_disc);

	SWITCH: {
		my $referer = $globals->http_referer();
		my ($ref_filename, $query) = split( /\?/, $referer, 2 );
		$ref_filename =~ s|/$||;     # lose trailing "/"s
		$referer = ($query =~ /[a-zA-Z0-9]/) ? 
			"$ref_filename?$query" : $ref_filename;
		$ref_filename =~ m|^http://([^/]+)(.*)|;
		my ($domain, $path) = ($1, $2);
		
		# first check if visitor is moving within our own site
		foreach my $synonym (@{$ra_site_urls}) {
			if( lc($ref_filename) eq lc($synonym) ) {
				push( @ref_norm, $t_rfs );
				push( @ref_sear, $t_rfs );
				push( @ref_keyw, $t_rfs );
				push( @ref_disc, $t_rfs );			
				last SWITCH;
			}
		}

		# else check if visitor came from checking an e-mail online
		foreach my $ident (@{$ra_discards}) {
			if( $ref_filename =~ m|$ident|i ) {
				push( @ref_norm, $t_rfo );
				push( @ref_sear, $t_rfo );
				push( @ref_keyw, $t_rfo );
				push( @ref_disc, $referer );
				last SWITCH;
			}
		}
		
		# else check if the referring domain is a search engine
		foreach my $dom_frag (keys %{$rh_engines}) {
			if( ".$domain." =~ m|[/\.]$dom_frag\.| ) {
				my $se_query = CGI::MultiValuedHash->new( 1, $query );
				my @se_keywords;
				
				my $kwpn = $rh_engines->{$dom_frag};
				my @kwpn = ref($kwpn) eq 'ARRAY' ? @{$kwpn} : $kwpn;
				foreach my $query_param (@kwpn) {
					push( @se_keywords, split( /\s+/, 
						$se_query->fetch_value( $query_param ) ) );
				}

				foreach my $kw (@se_keywords) {
					$kw =~ s/^[^a-zA-Z0-9]+//;  # remove framing junk
					$kw =~ s/[^a-zA-Z0-9]+$//;
				}

				# save both the file name and the search words used
				push( @ref_norm, $t_rfo );
				push( @ref_sear, $ref_filename );
				push( @ref_keyw, @se_keywords );
				push( @ref_disc, $t_rfo );
				last SWITCH;
			}
		}

		# otherwise, referer is probably a normal web site
		push( @ref_norm, $referer );
		push( @ref_sear, $t_rfo );
		push( @ref_keyw, $t_rfo );
		push( @ref_disc, $t_rfo );
	}

	$fn_normal and $self->update_one_count_file( $fn_normal, @ref_norm );
	$fn_search and $self->update_one_count_file( $fn_search, @ref_sear );
	$fn_keywords and $self->update_one_count_file( $fn_keywords, @ref_keyw );
	$fn_discards and $self->update_one_count_file( $fn_discards, @ref_disc );
}

######################################################################

sub update_one_count_file {
	my ($self, $filename, @keys_to_inc) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();

	push( @keys_to_inc, $rh_prefs->{$PKEY_TOKEN_TOTAL} );

	my $count_file = CGI::WPM::EventCountFile->new( 
		$globals->phys_filename_string( $filename ), 1 );
	$count_file->open_and_lock( 1 ) or return( 0 );
	$count_file->read_all_records();

	foreach my $key (@keys_to_inc) {
		$key eq '' and $key = $rh_prefs->{$PKEY_TOKEN_NIL};
		$count_file->key_increment( $key );
	}

	$count_file->write_all_records();
	$count_file->unlock_and_close();
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
This e-mail was sent at @{[$globals->today_date_utc()]} 
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

perl(1), CGI::WPM::Base, CGI::WPM::Globals, CGI::WPM::EventCountFile, Net::SMTP.

=cut
