# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk ;
use ExtUtils::testlib;
use Puppet::VcsTools::LogEdit;
require Tk::ErrorDialog; 
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

  # each entry is a hash made of 
  # - name : name of the field stored in log
  # - var : variable name used in internal hash (default = name) 
  # - type : is line, enum or array or text
  # - values : possible values of enum type
  # - mode : specifies if the value can be modified (r|w) (default 'w')
  # - pile : define how to pile the data when building a log resume.
  # - help : help string
  
my $logDataFormat = 
    [
     { 'name' => 'merged from', 'type' => 'line','var' => 'mergedFrom' },
     { 'name' => 'comes from', 'type' => 'line','var' => 'previous', 
       'help' => 'enter a version if it cannot be figured out by the tool' },
     { 'name' => 'misc' , 'var' => 'log', 
       'type' => 'text', 
       #'type' => 'line',
       'pile' => 'concat',
       'help' => {'class' => 'Puppet::VcsTools::LogEdit',
                  'section' => 'DESCRIPTION'} }
  ];



use strict ;

my $mw = MainWindow-> new ;

my %info = qw/log nothing_to_tell/;

my $he = $mw->LogEditor( 'format' => $logDataFormat) ;

$mw->Label(text => "First, click the 'edit' button") -> pack;

$mw -> Button
  (
   text => 'edit', 
   command => sub 
   {
     $mw -> withdraw ;
     my $res = $he->Show(revision=> '1.1', name => 'dummy', 'info' => \%info );
     if ($res)
       {
         warn "Archive pressed res is $res\nNew log is :\n",$info{log},"\n";
       }
     else
       {
         warn "Cancelled\n";
       }
     $mw -> destroy ;
   }
  ) -> pack;


MainLoop ; # Tk's

print "ok 2\n";

