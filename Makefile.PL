use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'CGI-WebsiteGenerator',
	VERSION_FROM => 'Globals.pm', # finds $VERSION
	PREREQ_PM => {
		'Class::ParamParser' => 1.03,
		'HTML::EasyTags' => 1.03,
		'Data::MultiValuedHash' => 1.06,
		'CGI::MultiValuedHash' => 1.06,
		'HTML::FormTemplate' => 1.05,
	},
);
