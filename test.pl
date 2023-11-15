#!/usr/bin/perl

#    test.pl: simple sample program to test the PCSC Perl wrapper
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

# $Id: test.pl,v 1.12 2004/05/30 20:10:11 rousseau Exp $

use ExtUtils::testlib;
use Chipcard::PCSC;
use Chipcard::PCSC::Card;

use warnings;
use strict;

my $hContext;
my @ReadersList;

my $hCard;
my @StatusResult;
my $tmpVal;
my $SendData;
my $RecvData;
my $sw;

#-------------------------------------------------------------------------------
print "Getting context:\n";
$hContext = new Chipcard::PCSC();
die ("Can't create the pcsc object: $Chipcard::PCSC::errno\n") unless (defined $hContext);
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print "Retrieving readers'list:\n";
@ReadersList = $hContext->ListReaders ();
die ("Can't get readers' list: $Chipcard::PCSC::errno\n") unless (defined($ReadersList[0]));
$, = "\n  ";
$" = "\n  ";
print "  @ReadersList\n" . '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print "Getting status change:\n";
my (@readers_states, $reader_state, $timeout, $event_state);
# create the list or readers to watch
map { push @readers_states, ({'reader_name'=>"$_"}) } @ReadersList;

@StatusResult = $hContext->GetStatusChange(\@readers_states);

for my $i (0..$#readers_states)
{
	print "reader: " . $readers_states[$i]{'reader_name'} . "\n";
	print "  ATR: " .
	Chipcard::PCSC::array_to_ascii($readers_states[$i]{'ATR'}) .  "\n" if (defined $readers_states[$i]{'ATR'});
	print "  state:\n";
	$event_state = $readers_states[$i]{'event_state'};
	print "    state changed\n" if ($event_state & $Chipcard::PCSC::SCARD_STATE_CHANGED);
	print "    card present\n" if ($event_state & $Chipcard::PCSC::SCARD_STATE_PRESENT);
	print "    card abstent\n" if ($event_state & $Chipcard::PCSC::SCARD_STATE_EMPTY);
	print "    card mute\n" if ($event_state & $Chipcard::PCSC::SCARD_STATE_MUTE);

	$readers_states[$i]{'current_state'} = $event_state;
}

if (! ($readers_states[0]{'event_state'} &
		$Chipcard::PCSC::SCARD_STATE_PRESENT))
{
	$timeout = 10 * 1000;	# 10 seconds
	print "Insert a card in the first reader please (timeout in $timeout ms)\n";
	@StatusResult = $hContext->GetStatusChange(\@readers_states, $timeout);
}
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print "Connecting to the card:\n";
$hCard = new Chipcard::PCSC::Card ($hContext);
die ("Can't create the reader object: $Chipcard::PCSC::errno\n") unless (defined($hCard));

$tmpVal = $hCard->Connect($ReadersList[0], $Chipcard::PCSC::SCARD_SHARE_SHARED);
unless ($tmpVal) {
	# Try to reconnect and reset if connect fails
	print "Connect failed: trying to reset the card:\n";
	$tmpVal = $hCard->Reconnect ($Chipcard::PCSC::SCARD_SHARE_SHARED, $Chipcard::PCSC::SCARD_PROTOCOL_T0, $Chipcard::PCSC::SCARD_RESET_CARD);
	die ("Can't reconnect to the reader '$ReadersList[0]': $Chipcard::PCSC::errno\n") unless ($tmpVal);
}
die ("Can't understand the current protocol: $hCard->{dwProtocol}\n")
	unless ($hCard->{dwProtocol}==$Chipcard::PCSC::SCARD_PROTOCOL_T0 ||
            $hCard->{dwProtocol}==$Chipcard::PCSC::SCARD_PROTOCOL_T1 ||
	        $hCard->{dwProtocol}==$Chipcard::PCSC::SCARD_PROTOCOL_RAW);
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print ("Setting up timeout value:\n");
die ("Can't set timeout: $Chipcard::PCSC::errno\n") unless ($hContext->SetTimeout (50));
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print "Getting status:\n";
@StatusResult = $hCard->Status();
die ("Can't get status: $Chipcard::PCSC::errno\n") unless ($StatusResult[0]);
print "Reader name is $StatusResult[0]\n";
print "State: $StatusResult[1]\n";
print "Current protocol: $StatusResult[2]\n";
print "ATR: " . Chipcard::PCSC::array_to_ascii ($StatusResult[3]) . "\n";
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print ("Initiating transaction:\n");
die ("Can't initiate transaction: $Chipcard::PCSC::errno\n") unless ($hCard->BeginTransaction());
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
#sleep (13);

print ("Exchanging data:\n");
$SendData = Chipcard::PCSC::ascii_to_array ("00 A4 01 00 02 01 00");
$RecvData = $hCard->Transmit($SendData);
die ("Can't transmit data: $Chipcard::PCSC::errno") unless (defined ($RecvData));

print "  Send -> " . Chipcard::PCSC::array_to_ascii ($SendData) . "\n";
print "  Recv <- " . Chipcard::PCSC::array_to_ascii ($RecvData) . "\n";
print '.'x40 . " OK\n";
# sleep (3);

#-------------------------------------------------------------------------------
print "TransmitWithCheck:\n";
$SendData = "00 A4 00 00 02 3F 00";	# select DF 3F 00
# wait for ".. .." since we the SW will depend on the inserted card
($sw, $RecvData) = $hCard->TransmitWithCheck($SendData, ".. ..", 1);
warn "TransmitWithCheck: $Chipcard::PCSC::Card::Error" unless defined $sw;

print "  Send -> $SendData\n";
print "  Recv <- $RecvData (SW: $sw)\n";
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print "ISO7816Error:\n";
print "$sw: " . &Chipcard::PCSC::Card::ISO7816Error($sw) . "\n";
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
# This test is commented since it is reader/driver specific and may do bad
# things for another reader. Reader your reader and driver
# specifications to know what data to use.
#
#print "Control\n";
#$SendData = Chipcard::PCSC::ascii_to_array ("02");
#$RecvData = $hCard->Control(0x42000001, $SendData);
#die ("Can't Control data: $Chipcard::PCSC::errno") unless (defined ($RecvData));
#
#print "  Send -> " . Chipcard::PCSC::array_to_ascii ($SendData) . "\n";
#print "  Recv <- " . Chipcard::PCSC::array_to_ascii ($RecvData) . "\n";
#print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print ("Ending transaction:\n");
die ("Can't terminate transaction: $Chipcard::PCSC::errno\n") unless ($hCard->EndTransaction($Chipcard::PCSC::SCARD_LEAVE_CARD));
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print "Disconnecting the card:\n";
$tmpVal = $hCard->Disconnect($Chipcard::PCSC::SCARD_LEAVE_CARD);
die ("Can't disconnect the Chipcard::PCSC object: $Chipcard::PCSC::errno\n") unless $tmpVal;
print '.'x40 . " OK\n";
#-------------------------------------------------------------------------------
print "Closing card object:\n";
$hCard = undef;
print '.'x40 . " OK\n";
#-------------------------------------------------------------------------------
print "Closing context:\n";
$hContext = undef;
#print '.'x40 . " OK\n";

# End of File #

