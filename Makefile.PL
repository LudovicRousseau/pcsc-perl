use ExtUtils::MakeMaker;
# See ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'      => 'Chipcard::PCSC',
    'VERSION_FROM' => 'PCSC.pm', # finds $VERSION
    'LIBS'      => [''],   # e.g., '-lm'
    'DEFINE'    => '-O2 -Wall',     # e.g., '-DHAVE_SOMETHING'
    'INC'       => '-I/usr/local/pcsc/include',     # e.g., '-I/usr/include/other'
	'PL_FILES'  => {},
);

