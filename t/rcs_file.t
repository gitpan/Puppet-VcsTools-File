# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN 
  { 
    $| = 1; 
    print "1..10\n"; 
  }
END {print "not ok 1\n" unless $loaded;}
use Tk ;
use Cwd ;
use ExtUtils::testlib;
use Puppet::VcsTools::File;
use Puppet::VcsTools::LogEdit;
use VcsTools::RcsAgent ;
use Puppet::Storage ;
use VcsTools::LogParser ;
use VcsTools::DataSpec::Rcs qw($description readHook);
require Tk::ErrorDialog; 

$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";
my $trace = shift || 0 ;

######################### End of black magic.


# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict ;

mkdir ("RCS",0755) or die "Can't mkdir RCS:$!" unless -d "RCS";

my $tfile ="rcs_dummy$>.txt";
my $olddir = $ENV{PWD};

chdir("RCS") or die "Can't chdir in RCS:$!";
chmod(0644,"$tfile,v") or die "Can't chmod $tfile,v:$!"  
  if -e "$tfile,v";
unlink("$tfile,v") or die "Can't unlink $tfile,v:$!" 
  if -e "$tfile,v";
chdir($olddir) or die "Can't chdir in $olddir:$!";

unlink($tfile) or die "Can't unlink $tfile:$!"if -e $tfile ;

open (FOUT,'>'.$tfile) or die "Can't open $tfile:$!";
print FOUT '$Revision$ '."\n\ndummy content\n";
close FOUT;

print "ok ",$idx++,"\n";

my %dbhash;

my $ds = new VcsTools::LogParser
  (
   description => $description,
   readHook => \&readHook
  ) ;
print "ok ",$idx++,"\n";

my $mw = MainWindow-> new ;
$mw->withdraw ;

my $he = $mw->LogEditor( 'format' => $ds) ;
print "ok ",$idx++,"\n";

Puppet::Storage->dbHash(\%dbhash);
Puppet::Storage->keyRoot('root');
VcsTools::RcsAgent->trace($trace);

my $agent = VcsTools::RcsAgent->new
  (
   name => $tfile,
   workDir => cwd()
  );

my $file = new Puppet::VcsTools::File 
  (
   storage=> new Puppet::Storage(name => $tfile) ,
   vcsAgent => $agent,
   name => $tfile,
   workDir => cwd(),
   dataScanner => $ds,
   logEditor => $he,
   trace => $trace,
   how => $trace ? 'print' : undef ,
   'topTk' => $mw
  );

print "ok ",$idx++,"\n";

my $res = $file->archiveFile(auto => 1) ;
print "not " unless defined $res;
print "ok ",$idx++,"\n";

$res = $file->checkOut(revision => '1.1', lock => 1);
print "not " unless defined $res;
print "ok ",$idx++,"\n";

open (FOUT,'>>'.$tfile) or die "Can't open $tfile:$!";
print FOUT "\nanother dummy content\n";
close FOUT;

$res = $file->archiveFile(auto => 1) ;
print "not " unless defined $res;
print "ok ",$idx++,"\n";

my $d = $file -> display( master => 1);
print "ok ",$idx++,"\n";

my $t = $d->getSlave('informations') ;

$t ->insert('end', "Select File->Check, then File->open History\n");
$t ->insert('end', "In history, double-click on 1.1 in the right ListBox\n");
$t ->insert('end', "Then click on button3 over the rectangle in the Canvas\n");
$t ->insert('end', "and select whatever menu entry you want.");

MainLoop ; # Tk's

print "ok ",$idx++,"\n";

