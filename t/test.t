#!/usr/bin/perl

#    test.pl: simple sample program based on test.pl to test the pcsc
#    Perl wrapper under Test::Harness
#    Copyright (C) 2001  Lionel Victor, 2003 Ludovic Rousseau
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# $Id: test.t,v 1.4 2006-05-04 12:52:10 rousseau Exp $

use ExtUtils::testlib;
use Chipcard::PCSC;
use Chipcard::PCSC::Card;

use strict;
use warnings;

my $hContext;
my @ReadersList;

my $hCard;
my @StatusResult;
my $tmpVal;
my $SendData;
my $RecvData;

print "1..9\n";

#-------------------------------------------------------------------------------
$hContext = new Chipcard::PCSC();
die ("not ok : Can't create the pcsc object: $Chipcard::PCSC::errno\n") unless (defined $hContext);
print "ok\n";

#-------------------------------------------------------------------------------
@ReadersList = $hContext->ListReaders ();
die ("not ok : Can't get readers' list: $Chipcard::PCSC::errno\n") unless (defined($ReadersList[0]));
print "ok\n";

#-------------------------------------------------------------------------------
$hCard = new Chipcard::PCSC::Card ($hContext);
die ("not ok : Can't create the reader object: $Chipcard::PCSC::errno\n") unless (defined($hCard));

$tmpVal = $hCard->Connect($ReadersList[0], $Chipcard::PCSC::SCARD_SHARE_SHARED);
unless ($tmpVal) {
	# Try to reconnect and reset if connect fails
	print "not ok : Connect failed: trying to reset the card:\n";
	$tmpVal = $hCard->Reconnect ($Chipcard::PCSC::SCARD_SHARE_SHARED,
	$Chipcard::PCSC::SCARD_PROTOCOL_T0, $Chipcard::PCSC::SCARD_RESET_CARD);
	die ("not ok : Can't reconnect to the reader '$ReadersList[0]':
	$Chipcard::PCSC::errno\n") unless ($tmpVal);
}
die ("not ok : Can't understand the current protocol: $hCard->{dwProtocol}\n")
	unless ($hCard->{dwProtocol}==$Chipcard::PCSC::SCARD_PROTOCOL_T0 ||
            $hCard->{dwProtocol}==$Chipcard::PCSC::SCARD_PROTOCOL_T1 ||
	        $hCard->{dwProtocol}==$Chipcard::PCSC::SCARD_PROTOCOL_RAW);
print "ok\n";

#-------------------------------------------------------------------------------
die ("not ok : Can't set timeout: $Chipcard::PCSC::errno\n") unless ($hContext->SetTimeout (50));
print "ok\n";

#-------------------------------------------------------------------------------
@StatusResult = $hCard->Status();
die ("not ok : Can't get status: $Chipcard::PCSC::errno\n") unless ($StatusResult[0]);
print "ok\n";

#-------------------------------------------------------------------------------
die ("not ok : Can't initiate transaction: $Chipcard::PCSC::errno\n") unless ($hCard->BeginTransaction());
print "ok\n";

#-------------------------------------------------------------------------------
$SendData = Chipcard::PCSC::ascii_to_array ("00 A4 01 00 02 01 00");
$RecvData = $hCard->Transmit($SendData);
die ("not ok : Can't transmit data: $Chipcard::PCSC::errno") unless (defined ($RecvData));
print "ok\n";

#-------------------------------------------------------------------------------
die ("not ok : Can't terminate transaction: $Chipcard::PCSC::errno\n")
unless ($hCard->EndTransaction($Chipcard::PCSC::SCARD_LEAVE_CARD));
print "ok\n";

#-------------------------------------------------------------------------------
$tmpVal = $hCard->Disconnect($Chipcard::PCSC::SCARD_LEAVE_CARD);
die ("not ok : Can't disconnect the PCSC object: $Chipcard::PCSC::errno\n") unless $tmpVal;
print "ok\n";

#-------------------------------------------------------------------------------
$hCard = undef;
$hContext = undef;

# End of File #

