package VcsTools::LogEdit ;

use strict;
use Carp qw/croak carp cluck/;
use Tk::ROText;
require Tk::Derived;

use vars qw(@ISA $VERSION %histInfo) ;
# %histInfo is used as a pool of historic logs used for recalls


$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

@ISA = qw(Tk::Derived Tk::Toplevel);
#use base qw(Tk::Toplevel);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

Tk::Widget->Construct('LogEditor');

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

# one widget must be created for each different log data format
sub Populate
  {
    my ($cw,$args) = @_ ;
    
    # mandatory parameters
    # format : logDataFormat ref
    # manager : History or File object
    # info : hash to edit and/or fill
    foreach (qw/format/)
      {
        $cw->BackTrace("$cw: No $_ defined\n") unless defined $args->{$_};
        $cw->{$_} = delete $args->{$_} ;
      }
 
    # retrieve format if we were passed the data scanner
    $cw->{format} = $cw->{format}->getDescription() 
      if (ref($cw->{format}) ne 'ARRAY');

    $cw->iconname('LogEditor');
    $cw->protocol('WM_DELETE_WINDOW' => sub {});
    $cw->transient($cw->Parent->toplevel);
    $cw->withdraw;

    $cw->{label} = '';
    $cw -> Label(textvariable => \$cw->{label}) -> pack ;
    
    foreach my $item (@{$cw->{'format'}})
      {
        $cw->BackTrace("$cw: No type defined in format for $item->{name}")
          unless defined $item->{type} ;

        my $mode = defined $item->{mode} ? $item->{mode} : '0' ;
        next if $mode eq 'h' ; # hidden

        my $state = $mode eq 'r' ? 'disabled' : 'normal' ;

        my $sf = $cw -> Frame (relief => 'sunken', bd => 2)
          -> pack(qw/fill x/) ;
        my $varName = defined $item->{var} ? $item->{var} : $item->{name} ;

        my $buttonFrame = $sf ;
        if ($item->{'type'} eq 'text')
          {
            $buttonFrame = $sf -> Frame -> pack(qw/side top/) ;
          }

        my $hstate = defined $item->{help} ? 'normal' : 'disabled' ;
        $buttonFrame -> Button 
          (
           qw/text help state/, $hstate,
           command => sub {$cw->showHelp($item->{help}) ;}
          )-> pack(qw/side right/);

        my $itemLabel = $buttonFrame -> Label 
          ( text => $item->{name}.' :', qw/width 20/)
            -> pack(qw/side left/) ;

        if ( $item->{'type'} eq 'enum')
          {
            $cw->BackTrace("$cw: enum $item->{name} has no values in format")
              unless defined $item->{'values'} ;
            
            foreach my $value (@{$item->{'values'}})
              {
                $sf->Radiobutton
                  (
                   text     => $value ,
                   variable => \$cw->{localInfo}{$varName},
                   relief   => 'flat',
                   state => $state,
                   value    => $value,
                  ) -> pack(-side => 'left', -pady => '2');
              }
          }
        elsif ($item->{type} eq 'array')
          {
            my $entry = $sf->Scrolled
              (
               qw/Entry -scrollbars s -relief sunken -width 40/,
               state => $state,
               textvariable => \$cw->{localInfo}{$varName} 
              ) -> pack(qw/side left fill x/) ;

            $buttonFrame -> Button 
              (
               text => 'recall' , 
               state => $state,
               command =>
               sub 
               {
                 my $tmp = pop @{$histInfo{$varName}} ;
                 return unless defined $tmp;
                 $cw->{localInfo}{$varName} = $tmp;
                 unshift @{$histInfo{$varName}}, $tmp ; 
               }
              ) -> pack(-side => 'right') ;
          }
        elsif ( $item->{type} eq 'text')
          {
            my $what = $mode eq 'r' ? 'ROText' : 'Text' ;
            my $w_t = $sf->Scrolled
              (
               $what ,
               qw/-scrollbars oe -relief sunken bd 2 -setgrid true -height 10/
              )-> pack(qw/side bottom/);


            $buttonFrame -> Button 
              (
               text => 'recall' , 
               command =>
               sub 
               {
                 my $tmp = pop @{$histInfo{$varName}} ;
                 $w_t -> delete ('0.0','end');
                 $w_t->insert('0.0',$tmp);
                 unshift @{$histInfo{$varName}}, $tmp ; 
               }
              ) -> pack(-side => 'right') ;

            $cw->{textWidget}{$varName} = $w_t ;
          }
        else
          {
            if (defined $item->{mode} and $item->{mode} eq 'r') 
              {
                $sf -> Label(textvariable => \$cw->{localInfo}{$varName})
                  ->pack(qw/-side left fill x/) ;
              }
            else
              {
                $sf -> Scrolled (qw/Entry -scrollbars s width 40/,
                                 textvariable => \$cw->{localInfo}{$varName}
                                ) -> pack(qw/-side left fill x/) ;
              }

            $buttonFrame -> Button 
              (
               text => 'recall' , command =>
               sub 
               {
                 my $tmp = pop @{$histInfo{$varName}} ;
                 $cw->{localInfo}{$varName} = $tmp ;
                 unshift @{$histInfo{$varName}}, $tmp ; 
               }
              ) -> pack(-side => 'right') ;
          } 
      }

    my $cf = $cw -> Frame -> pack ;
    $cf -> Button (text => 'cancel', 
                   command => sub {$cw->{result} = 0 ;})
      -> pack (side => 'left' ) ;

    $cf -> Button (text => 'reset', command => sub {$cw->resetInfo();})  
      -> pack (side => 'left' ) ;

    $cf -> Button (text => 'archive', command => 
                   sub {
                     $cw->storeLogInfoFromEdit() ;
                   }) 
      -> pack (side => 'left' ) ;
    
    $cw->ConfigSpecs('DEFAULT' => [$cw]) ;
    $cw->Delegates(DEFAULT => $cw) ;
    $cw->SUPER::Populate($args);

  }

sub showHelp 
  {
    my $cw = shift ;
    my $help = shift ;

    if (ref($help) eq 'HASH')
      {
        require Tk::Pod ;
        my $podSpec = $help->{class};
        $podSpec .= '/"'.$help->{section}.'"' if defined $help->{section} ;
        my ($pod)  = grep (ref($_) eq 'Tk::Pod',$cw->MainWindow->children) ;
        $pod = $cw->MainWindow->Pod() unless defined $pod ;
        $pod->Subwidget('pod')->Link('reuse',undef, $podSpec)
      }
    else
      {
        $cw ->Dialog('title'=> "$help help", text =>$help) -> Show();
      }
  }

#could be used with a Show methods
sub resetInfo
  {
    my $cw = shift ;

    # Store informations in localInfo in a format suitable for 
    # the widget
    foreach my $item (@{$cw->{'format'}})
      {
        my $varName = defined $item->{var} ? $item->{var} : $item->{name} ;
        my $dbitem = ref $cw->{info} eq 'HASH' ? 
          $cw->{info}{$varName} : $cw->{info}->getDbInfo($varName);

        if ($item->{type} eq 'array')
          {
            $cw->{localInfo}{$varName} = defined $dbitem ?
                  join(' ',@$dbitem) : undef;
          }
        elsif ($item->{type} eq 'text')
          {
            $cw->{textWidget}{$varName} -> delete ('0.0','end');
            $cw->{textWidget}{$varName} -> insert('0.0',$dbitem)
              if defined $dbitem ;
          }
        else
          {
            $cw->{localInfo}{$varName} = $dbitem;
          }
      }

  }

sub storeLogInfoFromEdit()
  {
    my $cw = shift ;

    # must store array items and text items
    foreach my $item (@{$cw->{'format'}})
      {
        my $varName = defined $item->{var} ? $item->{var} : $item->{name} ;
        my $dbitem ;

        if ($item->{type} eq 'array')
          {
            next unless defined $cw->{localInfo}{$varName} ;
            my @array = split (/[, \t]+/, $cw->{localInfo}{$varName} ) ;
            $dbitem = \@array ;
            push @{$histInfo{$varName}},$cw->{localInfo}{$varName} ; 
          }
        elsif ($item->{type} eq 'text')
          {
            my $str = $cw->{textWidget}{$varName} -> get('0.0','end');
            $dbitem = $str ;
            push @{$histInfo{$varName}},$str ; 
          }
        else
          {
            next unless defined $cw->{localInfo}{$varName} ;
            $dbitem = $cw->{localInfo}{$varName};
          }

        if (ref $cw->{info} eq 'HASH') {$cw->{info}{$varName} = $dbitem ;}
        else {$cw->{info}->storeDbInfo($varName => $dbitem);}
      }

    #print "Setting result from $cw->{result} to 1\n";
    $cw->{result} = 1 ;
    #print "result was set to $cw->{result}\n";
}

sub Show {

    # Dialog object public method - display the dialog.

    my ($cw, %args) = @_;
    my $grab_type = $args{grab};

    foreach (qw/info revision name/)
      {
        $cw->BackTrace("$cw: No $_ parameter passed to LogEditor->Show\n")
          unless defined $args{$_};
        $cw->{$_} = delete $args{$_} ;
      }

    if (ref($cw->{info}) ne 'HASH')
      {
        cluck "Usage of LogEdit on object ", ref($cw->{info}),
        " is deprecated";
      }

    $cw->{result}= undef ;

    # get info and put them in data struct refered to by the widgets
    $cw->resetInfo ();

    $cw->{label}="Edit log of $cw->{name}, version $cw->{revision}";

    my $old_focus = $cw->focusSave;
    my $old_grab  = $cw->grabSave;

    # Update all geometry information, center the dialog in the display
    # and deiconify it

    $cw->Popup(); 

    # set a grab and claim the focus.

    if (defined $grab_type && length $grab_type) {
        $cw->grab($grab_type);
    } else {
        $cw->grab;
    }
    $cw->waitVisibility  unless $cw->viewable;
    $cw->update;
    $cw->focus;

    # Wait for the user to respond, restore the focus and grab, withdraw
    # the dialog and return the label of the selected button.

    $cw->tkwait('variable' ,\$cw->{result});
    $cw->grabRelease;
    $cw->withdraw;
    &$old_focus;
    &$old_grab;
    #print "End of the Show\n";
    delete $cw->{info};
    return $cw->{result};

} # end Dialog Show method

1;

__END__

=head1 NAME

Puppet::VcsTools::LogEdit - Tk composite widget to edit a Vcs Log

=head1 SYNOPSIS


 my $eh = $widget->LogEditor( name => 'dummy', 
                            revision=> '1.1', 
                            'format' => $logDataFormat) ;

 $eh->Show(info => Storage_object_of_a_VcsTools_Version_object) ;

=head1 DESCRIPTION

This composite Tk Widget is used to edit the log information of a version
of a Vcs file. A version of a Vcs file is implemented in the 
L<VcsTools::Version> object. And the log information is stored in its
associated L<Puppet::Storage> class. This class must be passed to the
Show method so that the editor can modify the log informations.

The fields of the editor are set according to the 'format' parameter 
passed during the widget creation.

Each field feature a 'recall' button which will recall the last archived
value of the field. You may click several times on the 'recall' button to
get older values.

=head1 Constructor

=head2 LogEditor()

Parameters are :

=over 4

=item *

format : data format array reference. The LogEditor widget content 
will match the content of this data structure

=back

=cut

#'

=head1 METHODS

=head2 Show()

This method displays the dialog, waits for the user to click either 
'archive' or 'cancel'. If the user cancels the edition, Show returns 0.

If the user clicked 'archive', Show will store the edited data in the 
passed 'info' reference and returns 1.

Parameters are :

=over 4

=item *

name: name of the VCS file

=item *

revision : revision number of the log version to edit

=item *

info: hash ref or Puppet::Storage object which contains the log to
edit. If a hash ref is passed, its content will be modified, if a
Puppet::Storage object is passed, its permanent data will be modified.

=item *

grab: If global is specified a global (rather than local) grab is
performed.

=back

=head1 DESCRIPTION FORMAT

See L<VcsTools::LogParser/"DESCRIPTION FORMAT">

Each item of the description must have a type. According to the type,
the LogEditor will create a widget for this type:

=over 4

=item *

line: The editor uses an Entry widget to edit this type.

=item *

enum:  The editor uses a RadioButton widget to edit this type. The possible 
values of the Buttons are set by the 'values' parameter of the data format.

=item *

array: The editor uses an Entry widget to edit this type. Array element will
be separated by a comma or a white space.

=item *

text: The  editor uses an Text widget to edit this type.

=back

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1998-1999 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Tk(3), VcsTools::DataSpec::HpTnd(3)

=cut


