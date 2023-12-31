use ExtUtils::MakeMaker;
# See ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use Config;
use strict;

my $lddflags = "";
my $inc = "";

print "osname: $Config{'osname'}\n";
if ($Config{'osname'} eq "darwin")
{
	# Mac OS X
	$lddflags = $Config{lddlflags} . ' -framework CoreFoundation';
}
else
{
	if ($Config{'osname'} eq "MSWin32")
	{
		# Windows
	}
	else
	{
		# other Unixes
    	$inc = '`pkg-config --cflags libpcsclite`';
	}
}

print "LDDFLAGS: $lddflags\n";
print "INC: $inc\n";

WriteMakefile(
    'NAME'      => 'Chipcard::PCSC',
    'VERSION_FROM' => 'PCSC.pm', # finds $VERSION
    AUTHOR => ['Ludovic ROUSSEAU <ludovic.rousseau@free.fr>', 'Lionel VICTOR'],
    ABSTRACT => 'Communicate with a smart card using PC/SC from a Perl script',
    LICENSE => 'gpl_2',
    'LIBS'      => [''],   # e.g., '-lm'
    'LDDLFLAGS' => $lddflags,
    'DEFINE'    => '-O2 -Wall',     # e.g., '-DHAVE_SOMETHING'
    'INC'       => $inc,
    'PL_FILES'  => {},
    META_MERGE => {
        resources => {
            homepage => 'https://pcsc-perl.apdu.fr/',
        }
    }
);

