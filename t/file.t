# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $skipIt ;
BEGIN 
  { 
    $| = 1; 
    if (system('fls -hhptnofs /test_integ>/dev/null') ne 0)
      {
        warn "You don't have access to the test_integ HMS base on hptnofs\n",
        "Which is normal if you are not working at HP TID in Grenoble, France\n",
        "Skipping most of this test\n";
        print "1..1\n";
        $skipIt = 1;
      }
    else
      {
        print "1..7\n"; 
        $skipIt = 0 ;
      }
  }
END {print "not ok 1\n" unless $loaded;}
use Tk ;
use ExtUtils::testlib;
use Puppet::VcsTools::File;
use Puppet::VcsTools::LogEdit;
use VcsTools::LogParser ;
use VcsTools::DataSpec::HpTnd qw($description readHook);
require Tk::ErrorDialog; 
use Fcntl ;
use MLDBM qw(DB_File);
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";
my $trace = shift || 0 ;

exit if $skipIt ;

######################### End of black magic.


# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict ;

my $tfile ="dummy$>.txt";
 
#warn "heavy cleanup\n" if $trace;
#system("rm -f $tfile;futil -u -hhptnofs /test_integ/$tfile;echo y|futil -x -hhptnofs /test_integ/$tfile" );
print "ok ",$idx++,"\n";

my $file = 'test.db';
unlink($file) if -r $file ;

my %dbhash;
tie %dbhash,  'MLDBM',    $file , O_CREAT|O_RDWR, 0640 or die $! ;

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


my $fileO = new Puppet::VcsTools::File 
  (
   storageArgs => 
   {
    dbHash => \%dbhash,
    keyRoot => 'root'
   },
   vcsClass => 'VcsTools::HmsAgent',
   vcsArgs => 
   {
    hmsHost => 'hptnofs',
    hmsBase => 'test_integ'
    },
   name => $tfile,
   workDir => $ENV{'PWD'},
   dataScanner => $ds,
   logEditor => $he,
   how => 'print',
   'topTk' => $mw
  );

print "ok ",$idx++,"\n";

my $d = $fileO -> display( master => 1);
print "ok ",$idx++,"\n";

my $t = $d->getSlave('informations') ;

$t ->insert('end', "Select File->Check, then File->open History\n");
$t ->insert('end', "In history, double-click on 1.1 in the right ListBox\n");
$t ->insert('end', "Then click on button3 over the rectangle in the Canvas\n");
$t ->insert('end', "and select whatever menu entry you want.");

MainLoop ; # Tk's

print "ok ",$idx++,"\n";

