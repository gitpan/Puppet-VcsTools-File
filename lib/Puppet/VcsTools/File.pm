package Puppet::VcsTools::File ;
use Carp;
use strict;
use Puppet::Show ;
use base 'VcsTools::File' ;


use vars qw($VERSION);

use AutoLoader qw/AUTOLOAD/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;


## Generic part

sub new
  {
    my $type = shift ;
    my %args = @_ ;
    local $_;

    my $self = {};

    $self->{body} = new Puppet::Show
      (
       cloth => $self,
       podName => 'Puppet::VcsTools::File',
       podSection => 'WIDGET USAGE',
       @_
      ) ;

    if (defined $args{storageArgs})
      {
        # transition code, should be removed sooner or later
        carp "new $type $args{name}: storageArgs is deprecated";
        $self->{storageArgs}=$args{storageArgs};
      }
    elsif (defined $args{storage})
      {
        # we will keep only this parameter
        $self->{storage}= $args{storage};
      }
    else
      {
        croak ("No storage arg passed to $type::$self->{name}\n")
      }
       
    # this will also be deprecated sooner or later
    $self->{usage} = $args{usage} || 'File' ;
   
    # vcs agent
    if (defined $args{vcsClass})
      {
        $self->{vcsClass}=$args{vcsClass};
        $self->{vcsArgs}=$args{vcsArgs};
      }
    elsif (defined  $args{vcsAgent})
      {
        $self->{vcsAgent}=$args{vcsAgent};
      }
    else
      {
        croak ("No vcsAgent passed to $type::$self->{name}\n")
      }

    # mandatory parameter
    foreach (qw/name dataScanner logEditor topTk workDir/)
      {
        die "No $_ passed to $type::$self->{name}\n" unless 
          defined $args{$_};
        $self->{$_} = delete $args{$_} ;
      }
    
    # optional parameter
    foreach (qw/test/)
      {
        $self->{$_} = delete $args{$_} ;
      }

    $self->{trace} = $args{trace} || 0 ;
    
    $self->{workDir} .= '/' unless $self->{workDir} =~ m!/$! ;

    bless $self,$type ;
    
    $self->init(@_);
    return $self;

  }


     
1;

__END__

=head1 NAME

Puppet::VcsTools::File - Tk GUI for VCS file management

=head1 SYNOPSIS

 use Tk ;
 use Puppet::VcsTools::File;
 use Puppet::VcsTools::HistEdit;
 use VcsTools::LogParser ;
 use VcsTools::DataSpec::HpTnd qw($description readHook);
 use Fcntl ;
 use MLDBM qw(DB_File);

 my %dbhash;
 tie %dbhash,  'MLDBM',    $file , O_CREAT|O_RDWR, 0640 or die $! ;

 my $ds = new VcsTools::LogParser
  (
   description => $description,
   readHook => \&readHook
  ) ;

 my $mw = MainWindow-> new ;
 $mw->withdraw ;

 my $he = $mw->LogEditor( 'format' => $ds) ;

 my $fileO = new Puppet::VcsTools::File 
  (
   dbHash => \%dbhash,
   keyRoot => 'root',
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
   'topTk' => $mw
  );

 $fileO -> display( master => 1);

 MainLoop ;

=head1 DESCRIPTION

This class provides a GUI to the L<VcsTools::File> class. 

The widget provides all the functionnalities to edit, archive, lock, 
unlock, change the mode of a file.

The widget also provide an 'open history' menu to call the 
L<Puppet::VcsTools::History> widget which will let you work on the 
history of a file. Moreover, this widget will let you edit the
log a each version of a file, if you want to modify it.

=head1 CAVEATS

The file B<must> contain the C<$Revision: 1.3 $> VCS keyword.

=head1 WIDGET USAGE

The File widget contains a sub-window featuring:

=over 4

=item *

A revision label to indicate the revision of the current file.

=item *

A 'writable' check button, which indicated the status of the file and is able
to change its mode.

=item *

A 'locked'check button, which indicated the lock status of the file and is able
to change its lock.

=back

By default, all these menus and buttons are disabled until the user
performs a File->check through the menu.

The File menu contains several commands :

=over 4

=item *

open history: Will open the history menu.

=item *

check: to get the revision, mode, and lock status of the current file.

=item *

archive: to archive the file (Enabled only if the file is writable).

=item *

create archive: to create an archive of the file (Enabled only if the file 
is writable and the archive does not exist).

=item *

edit: to edit the file (Enabled only if the file is writable or if the file
does not yet exist).

=back

The File object will add some functionnalities to the History object while
opening it :

=over 4

=item *

A 'merge' global menu: To perform a merge on 2 selected revision.

=item *

A 'show diff' global menu: To show a diff between 2 selected revision.

=item *

Button 2 is bound to arrows to show the diff between the 2 revisions next
to the arrow.

=item *

A 'show diff' command is also added to the arrow popup menu.

=item *

Button 2 is bound to nodes to show the content of this revision.

=item *

An 'edit log' entry is added to the popup menu of the nodes and arrows.

=back

=head1 Constructor

=head2 new(...)

Will create a new File object.

Parameters are those of L<VcsTools::File/"new(...)">. plus :

=over 4

=item *

topTk : Tk top window reference.

=back


=head1 Generic methods

See L<VcsTools::File/"check()">

=head2  display()

Will launch a widget for this object.

=head2 archiveFile(...)

See L<VcsTools::File/"archiveFile(...)">.

Feature one more parameter : The user may pass a 'auto' parameter set
to 1 if an interactive archive is not desired. (default 0)

=head1 History handling methods

See L<VcsTools::File/"createHistory()">,  L<VcsTools::File/"edit()">
L<VcsTools::File/"getRevision()">, L<VcsTools::File/"checkWritable()">,
L<VcsTools::File/"chmodFile(...)">, L<VcsTools::File/"writeFile(...)">


=head2 openHistory()

Will create a L<Puppet::VcsTools::History> object for this file and
open its display.

=head1 Handling the real file

See L<VcsTools::File/"createLocalAgent()">,
L<VcsTools::File/"edit()">, L<VcsTools::File/"getRevision()">, 
L<VcsTools::File/"checkWritable()">, L<VcsTools::File/"chmodFile(...)">,
L<VcsTools::File/"writeFile(...)">

=head1 Handling the VCS part

See L<VcsTools::File/"createVcsAgent()">, L<VcsTools::File/"checkArchive()">,
L<VcsTools::File/"changeLock(...)">, L<VcsTools::File/"checkOut(...)">,
L<VcsTools::File/"getContent(...)">, L<VcsTools::File/"archiveLog(...)">,
L<VcsTools::File/"getHistory()">, L<VcsTools::File/"showDiff(...)">,
L<VcsTools::File/"checkIn(...)">

=head2 merge(...)

Will open a GUI to merge the 2 revisions. Will use xemacs ediff merge 
to perform the actual merge.

Parameters are :

=over 4

=item *

rev1 : one of the revisions to merge.

=item *

rev2: the other.

=back

The ancestor of rev1 and rev2 will be computed by the L<VcsTools::History>
object.


=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1998 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Tk(3), Puppet::Any(3), VcsTools::DataSpec::HpTnd(3), 
VcsTools::Version(3), VcsTools::File(3)

=cut


sub display
  {
    my $self = shift ;
    my $top = $self->{body}->display
      (
       onDestroy => sub 
       {
         #print "cleaning up Tk private hash\n";
         print "Whoa there Tk private hash is not defined\n" unless
           defined $self->{tk} ;
         delete $self->{tk};
       },
       @_
      );

    return unless defined $top;
    require Tk::Multi::Frame;
    require Tk::Multi::Text;

    # must add a open history command
    
    # must add menu button related to the graph funcionnality
    # i.e draw, merge, show diff
    # these function will ask for currently selected nodes
    $top->Subwidget('fileMenu')->command
      (
       -label => 'check', 
       command => sub {$self->check ;}
      ) ;

    $self->{tk}{openHistButton} = 
      $top->Subwidget('fileMenu')->command
        (
         -label => 'open history...', 
         state=> 'disabled',
         command => sub {$self->openHistory;}
        ) ;
    
    $self->{tk}{createArchiveButton} = 
      $top->Subwidget('fileMenu')->command
        (
         -label => 'create archive',
         -state => 'disabled',
         command => sub 
         {
           $self->SUPER::archiveFile();
           $self->updateButtonCfg();
         }
        ) ;

    $self->{tk}{archiveButton} = 
      $top->Subwidget('fileMenu')->command
        (
         -label => 'archive...',
         -state => 'disabled',
         command => sub {$self->archiveFile();}
        ) ;

    $self->{tk}{editButton} = 
       $top->Subwidget('fileMenu')->command
        (
         -label => 'edit',
         -state => 'disabled',
         command => sub {$self->edit();}
        ) ;

    $top->newSlave
      (
       'type' => 'MultiText', 
       'title' => 'informations',
       side => 'top',
       'hidden' => 0 
      );

    my $f = $top->newSlave
      (
       'type' => 'MultiFrame', 
       'title' => 'file',
       side => 'top'
      );

    require Tk::Checkbutton;
    $f -> Label (text => "File: $self->{name} ") ->  pack(qw/side left/) ;   
    $f -> Label (textvariable => \$self->{status}{source})->pack(qw/side left/) ;
    $f -> Label (text => " ") ->  pack(qw/side left/) ;   
    $f -> Label (textvariable => \$self->{status}{archive})
      ->pack(qw/side left/);

    $self->{tk}{lockButton} = 
      $f -> Checkbutton
        (
         text => 'locked', 
         variable => \$self->{myMode}{locked},
         state => 'disabled',
         command => sub
         {
           my $r = $self->changeLock( lock => $self->{myMode}{locked});
           $self->{myMode}{locked} = 1-  $self->{myMode}{locked} unless 
             defined $r ;
         }
        )
        -> pack(qw/side right/) ;      

    $self->{tk}{writeButton} = 
      $f -> Checkbutton
        (
         text => 'writable', 
         variable => \$self->{myMode}{writable},
         state => 'disabled',
         command => sub
         {
           my $r = $self->chmodFile(writable => $self->{myMode}{writable});
           $self->{myMode}{writable} = 1-$self->{myMode}{writable} unless 
             defined $r ;
         }
        )
        -> pack(qw/side right/) ;      

    $f -> Label (textvariable => \$self->{myMode}{'revision'}) 
      ->  pack(qw/side right/) ;   
    $f -> Label (text => ' revision: ') ->  pack(qw/side right/) ;   
    #added by Bob
    return $top;
  }

# open correct window
# user select archive
# File set up default info array,
# File run editor on default array
# user select archive button
# File checks-in the file and asks history to create new version.

sub archiveFile 
  {
    my $self = shift ;
    my %args = @_ ;

    my $infoRef = $args{info} || {};
    my $version = $args{revision} || $self->{myMode}{revision} ;
    my $auto = defined $args{auto} ? $args{auto} : 0 ;

    my $newRev = $self->prepareArchive(@_);
    return undef unless defined $newRev ;

    my $h = $self->createHistory() ;

    if ($auto)
      {
        $self->SUPER::archiveFile 
          (
           revision => $args{revision},
           'info' => $infoRef
          ) ;
      }
    else
      {
        my $top = $self->{body}->myDisplay() || $self->display();

        my $title = "Archiving $self->{name} from $version";
        # create a new multi slave for the archive
        my $f = $top->newSlave ('type' => 'MultiFrame', 'title' => $title);

        my $e = $f -> Entry (textvariable => \$newRev, width=> 6) 
          -> pack (qw/side right fill x expand 1/) ;

        $f -> Label (text => "in version: ") -> pack (side => 'right');

        my $cancelb;
        $f -> Button 
          (
           'text' => 'do archive...',
           'command' => sub 
           {
             $e->configure(state =>'disabled') ;
             $cancelb->configure(state =>'disabled') ;
             $self->{logEditor}->Show
               (
                name => $self->{name},
                revision => $newRev,
                info => $infoRef
               )
                 and 
                   $self->SUPER::archiveFile
                     (
                      revision=> $newRev, 
                      'info' => $infoRef,
                     ) ;
             $top->destroySlave($title);
           }
          ) -> pack (side => 'left' ) ;
        
        $f -> Button 
          (
           'text' => 'show diff',
           'command' => sub 
           {
             my $res = $self-> showDiff( rev1 => $version) ;
             $self->showResult($res) if defined $res;
           },
           'state' => defined $version ? 'normal' : 'disabled'
          ) -> pack (side => 'left' ) ;
        
        $cancelb = $f -> Button 
          (
           'text' => 'cancel',
           'command' => sub {$top->destroySlave($title) ; }
          ) -> pack (side => 'right' ) ;
        $f->waitWindow;
      }
  }

# internal
sub showResult
  {
    my $self = shift ;
    my $top = $self->{body}->myDisplay() || $self->display();
    my $text = $top->getSlave('informations');

    $text->clear() ;

    my $ref =shift ;
    my $str = ref($ref) eq 'ARRAY' ? join("\n",@$ref) : $ref ;
    return unless defined $str ;

    $text->insertText($str) ;
  }

# end Generic part

## Handling the history part

sub createHistory 
  {
    my $self = shift ;

    # handles legacy code 
    my @store = defined $self->{storageArgs} ? 
      (storageArgs => $self->{storageArgs}) :
      (storage => $self->{storage}) ;

    if (not defined $self->{body}->getContent('history'))
      {
        require Puppet::VcsTools::History ;
        my $how = $self->{trace} ? 'warn' : undef ;
        my $h = new Puppet::VcsTools::History 
          (
           usage => $self->{usage},
           @store,
           topTk => $self->{topTk},
           how => $how,
           editor => $self->{logEditor},
           trace => $self->{trace},
           name => 'history',
           title => $self->{name},
           dataScanner => $self->{dataScanner}
          );
        $self->{body}->acquire(body => $h->body());
      }

    return $self->{body}->getContent('history')->cloth();
  }

sub openHistory
  {
    my $self = shift ;

    my $h = $self->createHistory() ;
    # create or raise the display, and then get the display ref
    my $htop =  $h->display  || $h->body()->myDisplay(); 
    
    my $tree = $h->getTreeGraph() ;

    $tree -> command
      (
       on => 'menu',
       label => 'merge', 
       command => sub 
       {
         my @revs = $tree->getSelectedNodes();
         if (defined @revs and scalar(@revs) == 2) 
           {
             $self->merge ( rev1 => $revs[0], rev2 => $revs[1]);
           }
         else {print scalar(@revs)," nodes selected\n";}
       }
      );
    
    $tree -> command
      (
       on => 'menu',
       -label => 'reload from archive', 
       command => sub 
       {
         $self->updateHistory();
       }
      );
    
    $tree -> command
      (
       on => 'menu',
       -label => 'show diff', 
       command => sub 
       {
         my @revs = $tree->getSelectedNodes();
         if (defined @revs and scalar(@revs) == 2)
           {
             my $res = $self->showDiff
               ( 
                rev1 => $revs[0],
                rev2 => $revs[1],
               );
             $h->showResult($res);
           }
         else
           {
             print scalar(@revs)," nodes selected\n";
           }
       }
      );
    
    my $showDiff = sub 
      {
        my %args = @_ ;
        my $ref = $self->showDiff (rev1 => $args{from} , rev2 => $args{to});
        $h->showResult($ref) ;
      } ;

    $tree->arrowBind
      (
       button => '<2>',
       color => 'yellow',
       command => $showDiff
      );
    
    $tree->command
      (
       on => 'arrow',
       label => 'show diff',
       command => $showDiff
      ) ;


    # bind button <2> on nodes to show content
    $tree->command
      ( 
       on => 'node',
       label => 'show content',
       command => sub 
       {
         my %args = @_ ;
         my $ref = $self->getContent(revision => $args{nodeId}) ;
         $h->showResult($ref) ;
       }
      ) ;

    $tree->command
      ( 
       on => 'node',
       label => 'check-out',
       command => sub 
       {
         my %args = @_ ;
         my $ref = $self->checkOut(revision => $args{nodeId},lock => 0) ;
         $h->showResult($ref) ;
       }
      ) ;

    my $editLog = sub
      {
         my  %args = @_ ;
         my $rev = $args{to} || $args{nodeId} ;
         $self->checkArchive() ;
         my $iref = $h->getInfo($rev) ;
         my $res = $self->{logEditor}->Show
           (
            name => $self->{name},
            revision => $rev,
            info => $iref
           );
         
         if ($res)
           {
             # archive Log
             $self->archiveLog
               (
                revision => $rev,
                info => $iref
               );
           }
      };

    $tree->command 
      (
       on => 'arrow', 
       label =>'edit log',
       command => $editLog
      ) if defined $self->{logEditor};

    $tree->command
      (
       on => 'node',
       label =>'edit log',
       command => $editLog
      ) if defined $self->{logEditor} ;

  }

# end history part

## Handling the real file part

sub checkWritable
  {
    my $self = shift ;
    my $res =$self->SUPER::checkWritable(@_);
    return undef unless defined $res ;
    $self->updateButtonCfg() ;
    return $res ;
  }

sub checkArchive
  {
    my $self = shift ;
    my $res = $self->SUPER::checkArchive(@_);
    return undef unless defined $res ;
    $self->updateButtonCfg() ;
    return $res ;
  }

sub checkExist
  {
    my $self = shift ;
     my $res =  $self->SUPER::checkExist(@_);
    return undef unless defined $res ;
    $self->updateButtonCfg() ;
    return $res ;
  }

sub updateButtonCfg
  {
    my $self = shift ;
    return unless defined $self->{tk};

    my ($wr,$exist,$locked) = @{$self->{myMode}}{qw/writable exists locked/};
    
    my $arch = $self->{archive}{exists};

    my $state = (not $exist or ($exist and defined $wr and $wr)) ? 
      'normal' : 'disabled' ;
    $self->{tk}{editButton}->configure(state =>$state ); 

    $state =  $exist ? 'normal' : 'disabled' ;
    $self->{tk}{writeButton}->configure(state => $state) ;

    $state = ($exist and not $arch) ? 'normal' : 'disabled' ;
    $self->{tk}{createArchiveButton}->configure(state => $state) ;
    
    $state = $arch ? 'normal' : 'disabled' ;
    $self->{tk}{openHistButton}->configure(state => $state) ;

    $state = ($arch and $exist) ? 'normal' : 'disabled' ;
    $self->{tk}{lockButton}->configure(state => $state) ;

    return unless defined $wr ;

    $state = ($arch and $exist and $wr) ? 'normal' : 'disabled' ;
    $self->{tk}{archiveButton}->configure(state => $state) ;
  }

sub chmodFile
  {
    my $self = shift ;
    my $res = $self->SUPER::chmodFile(@_);
    return undef unless defined $res;
    $self->updateButtonCfg() ;
    return $res;
  }

#internal


# end real file part

## Handling the archive (VCS) part


sub checkOut
  {
    my $self = shift ;
    my $res=$self->SUPER::checkOut(@_);
    return undef unless defined $res ; 
    $self->updateButtonCfg() ;
    return $res ;
  }

sub checkIn
  {
    my $self = shift ;
    my $res= $self->SUPER::checkIn(@_);
    return undef unless defined  $res ; 
    $self->updateButtonCfg() ;
    return $res ;
  }

 
sub changeLock
  {
    my $self = shift ;
    my $res= $self->SUPER::changeLock(@_);
    return undef unless defined  $res ; 
    $self->updateButtonCfg() ;
    return $res ;
  }

# end VCS part


# pas revue en dessous
sub merge
  {
    my $self = shift ;
    my %args = @_ ;
    
    my $rev1 = $args{rev1} ;
    my $rev2 = $args{rev2};
    #belowRef is a reference on a scalar containing the revision number of the merged revision.
    #it will be set when the user chooses a version under which it will be merged.
    my $belowRef = $args{belowRef};
    die "$self->{name}::merge rev1 or rev2 are not defined\n" unless 
      defined $rev1 and defined $rev2 ;

    my $top = $self->{body}->myDisplay() || $self->display();
    my $h = $self->createHistory();

    # get rev1 object
    my $obj1 = $h->getVersionObj($rev1) ;
    my $ancestor = $obj1->findAncestor($rev2);

    my $f = $top->newSlave
      (
       'type' => 'MultiFrame', 
       'title' => 'merge file '.$self->{name}
      );

    my $lf = $f -> Frame -> pack ;
    $lf -> Label
      (text => "Merging file $self->{name} $rev1 with $rev2 from $ancestor")
      -> pack (side => 'left') ;

    my ($below, $newRev, $other);
    my ($cancelB, $archiveB, $ediffB, $checkOutB,@belowWidgets)   ;

    my $belowf = $f -> Frame -> pack(fill => 'x') ;
    $belowf ->Label (text => "merge below :") -> pack (side => 'left');

    if ($rev2 ne $ancestor and $rev1 ne $ancestor)
      {
        foreach ($rev1,$rev2)
          {
            # skip stupid choices
            next if ( ($_ eq $rev1 and $rev2 eq $ancestor) or
                      ($_ eq $rev2 and $rev1 eq $ancestor) ) ;

            push @belowWidgets, $belowf -> Radiobutton
              (
               text => $_, 
               value => $_, 
               variable => \$below,
               command => sub 
               {
                 $newRev = $h->guessNewRev($below); 
                 $checkOutB -> configure(state => 'normal');
               }
              ) -> pack (side => 'left');
          }
      }
    else
      {
        $below = $rev1 eq $ancestor ? $rev2 : $rev1 ;
        $newRev = $h->guessNewRev($below); 
        $checkOutB -> configure(state => 'normal');
      }

    $belowf ->Label (text => "in revision : ") -> pack (side => 'left');
    my $e = $belowf -> Entry 
      (
       textvariable => \$newRev,
      ) -> pack (qw/side left expand 1 fill x/ ) ;
    $e->bind('<Return>' => sub{$checkOutB -> configure(state => 'normal');});

    push @belowWidgets, $e ;


    my $buttonf = $f -> Frame -> pack ;

    $cancelB = $buttonf -> Button 
      (
       text => 'cancel' ,
       state => 'normal',
       command => sub 
       { 
         $top->destroySlave('merge file '.$self->{name}) ;
         $self->mergeCleanup() ; 
       }
      ) -> pack (side => 'right');

    $checkOutB = $buttonf -> Button 
      (
       text => 'check-out' ,
       state => 'disabled',
       command => sub 
       { 
         # must get 1 or 3 files and lock the current file
         $other = $rev1 eq $below ? $rev2 : $rev1 
           unless $rev2 eq $ancestor or $rev1 eq $ancestor  ;

         my $res = $self->setUpMerge(below => $below,
                                     ancestor => $ancestor,
                                     other => $other);
         if (defined $res)
           {
             if ($rev2 eq $ancestor or $rev1 eq $ancestor)
               {$archiveB -> configure(state => 'normal') ;}
             else 
               {$ediffB -> configure(state => 'normal') ;}
             $checkOutB -> configure(state => 'disabled') ;
             map($_->configure(state => 'disabled'),@belowWidgets);
           }
         else
           {
             die "Couldn't get files for merge ",shift,"\n";
           }
       }
      ) -> pack (side => 'right');

    $ediffB = $buttonf -> Button
      (
       text => 'ediff' ,
       state => 'disabled',
       command => sub 
       { 
         $self->createLocalAgent unless defined $self->{localAgent} ;
         my $res = $self->{localAgent}->merge (%{$self->{mergeFiles}}) ;
         if ($res) {$archiveB->configure(state => 'normal') ;}
         else {die "Ediff failed : ",$self->{localAgent}->error(),"\n";}
       }
      ) -> pack (side => 'right');

    $archiveB = $buttonf -> Button
      (
       text => 'archive merge' ,
       state => 'disabled',
       command =>
       sub
       {
         my $info = $h -> buildCumulatedInfo($other,$ancestor);
         #set the variable reference
         $$belowRef = $newRev;
         $info->{mergedFrom} = $other ;
         $self->{logEditor}->Show
           (
            name => $self->{name},
            revision => $newRev,
            info => $info
           )
             and 
               $self->SUPER::archiveFile
                 (
                  revision => $newRev,
                  info => $info
                  );
         
         $top->destroySlave('merge file '.$self->{name}) ;
         $self->mergeCleanup() ;
       }
      )
      -> pack (side => 'right');

  }



1;
