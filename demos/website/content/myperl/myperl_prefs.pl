my $rh_preferences = { 
	vrp_handlers => {
		modules => {
			wpm_module => 'CGI::WPM::Static',
			wpm_prefs => { filename => 'myperl.html' },
		},
		paramparser => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'Class::ParamParser',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'ParamParser.pm',
			},
		},
		tagmaker => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'HTML::TagMaker',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'TagMaker.pm',
			},
		},
		formmaker => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'HTML::FormMaker',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'FormMaker.pm',
			},
		},
		hashofarrays => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'CGI::HashOfArrays',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'HashOfArrays.pm',
			},
		},
		sequentialfile => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'CGI::SequentialFile',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'SequentialFile.pm',
			},
		},
		eventcountfile => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'CGI::EventCountFile',
				author => 'Darren Duncan',
				created => '',
				updated => 'version 1.01 on 2000 August 7',
				filename => 'EventCountFile.pm',
			},
		},
		base => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'CGI::WPM::Base',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'Base.pm',
			},
		},
		content => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'CGI::WPM::Content',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'Content.pm',
			},
		},
		globals => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'CGI::WPM::Globals',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'Globals.pm',
			},
		},
		usage => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'CGI::WPM::Usage',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'Usage.pm',
			},
		},
		multipage => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'CGI::WPM::MultiPage',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'MultiPage.pm',
			},
		},
		redirect => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'CGI::WPM::Redirect',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'Redirect.pm',
			},
		},
		static => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'CGI::WPM::Static',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'Static.pm',
			},
		},
		segtextdoc => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'CGI::WPM::SegTextDoc',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'SegTextDoc.pm',
			},
		},
		mailform => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'CGI::WPM::MailForm',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'MailForm.pm',
			},
		},
		guestbook => {
			wpm_module => 'CGI::WPM::SegTextDoc',
			wpm_prefs => {
				title => 'CGI::WPM::GuestBook',
				author => 'Darren Duncan',
				created => '',
				updated => '',
				filename => 'GuestBook.pm',
			},
		},
	},
	def_handler => 'modules',
};

