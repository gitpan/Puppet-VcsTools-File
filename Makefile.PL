use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'	   => 'Puppet-VcsTools-File',
   'VERSION' => '1.003',
   'EXE_FILES' => [qw/hmsWork rcsWork/],
   'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
   ($] >= 5.005 ?
    (ABSTRACT   => 'GUI for VCS management tools',
     AUTHOR     => 'Dominique Dumont (domi@barrayar.grenoble.hp.com)') : ()),
   'PREREQ_PM' =>
   {
    'Tk' => 0,
    'Tk::ROText' => 0,
    'Puppet::Show' => '1.003',
    'MLDBM' => 0,
    'DB_File' =>0,
    'String::ShellQuote' => 0,
    'VcsTools::File' => '1.005',
    'Puppet::VcsTools::History' => '1.005'
   }
  );
