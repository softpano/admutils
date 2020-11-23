#!/usr/bin/perl
# dir_favorites.pl -- process favorites and create aliases for the most used directories
# Copyright Nikolai Bezroukov 2007-2020
# Licensed under the original BSD license
#
# static list of favorites is $HOME/.config/dir_favorites.$HOST
#
#--- Development History
#
# Ver      Date        Who        Modification
# ====  ==========  ========  ==============================================================
# 1.00  2007/07/02  Bezroun   Initial implementation
# 2.00  2008/09/16  Bezroun   Alias generation added
# 3.00  2013/04/17  Bezroun   Pipe is replaced with internal processing
# 4.00  201910/19   Bezroun   Integration with Midnight commander added
# 4.10  2019/10/30  Bezroun   Some errors corrected. Logic improved
# 4.20  2019/10/31  Bezroun   Fading of favorites based on line number implemented; older frequently used directory now have less weight 
# 4.21  2019/10/31  Bezroun   Empty entries are now excluded 
# 4.30  2019/11/07  Bezroun   Comments in static favorites in MC are allowed 
# 4.40  2020/11/18  Bezroun   History is now truncated to 1000 most recent items on each invocation
# 4.50  2020/11/19  Bezroun   Midnight command favorites generation now is optional (you need to specify option -m to enable it)
# 4.51  2020/11/19  Bezroun   Correction for the generation of cd-0 .. -cd-9 and cd- cd-- and cd--- aliases
#======================================================================================

   $VERSION='4.51'; # Nov 19, 2020
   $debug=0;
   $HOME=$ENV{'HOME'};
   chomp($HOST=`hostname -s`);
   %ignore_dups=($HOME=>1,'/etc'=>1,'/'=>1); # exclude HOME; /etc/is used as separator between static part and dynamic part
   $mc_fav_flag=0; # midnight commande favore generation flag 
   
#
# Check if we need to change midnight commander favorites
#
   if ( scalar(@ARGV)>0 && $ARGV[0] eq '-m' ){
      $mc_fav_flag=1;
   }   
#
# Process static favorite list; create exclution array so that those directories did not clutter the list of frequently used directores (%ignore) 
   
   $dir_favorites="$HOME/.config/dir_favorites.$HOST";
   if( -f $dir_favorites ){
      open (SYSIN,'<',$dir_favorites);
      $i=0;
      while (<SYSIN>) {
         next if( substr($_,0,1) eq '#' ); # comments
         chomp;
         next if (exists($ignore_dups{$_}) ); # discard duplicates
         $ignore_dups{$_}=1;
         $static_fav[$i++]=$_;
      }
      close SYSIN;
      
   }
#
# Process dynamic part of the favorite list
# emulating open (SYSIN, "uniq $HOME/.config/dir_history | sort | uniq -c | sort -rn | cut -c 9- | tac |");
#
# This is dynamic part of history; cur it to the last 1K lines. 
#
   unless (-f "$HOME/.config/dir_history") { die("File $HOME/.config/dir_history does not exits\n") }
   open (SYSIN,'<',"$HOME/.config/dir_history") || die("Can't open $HOME/.config/dir_history for reading\n"); 
   while($d=<SYSIN>) {
       $raw_hist[$m++]=$d;
   }
   if(scalar(@raw_hist)>1000){
      # we need to rewrite dir histrory truncating it 
      splice(@raw_hist,0,scalar(@raw_hist)-1000); # tail of last 1K lines
      open(SYSOUT,'>',"$HOME/.config/dir_history") || die("Can't open $HOME/.config/dir_history for writing\n");
      print SYSOUT @raw_hist;
      close SYSOUT;
   }      
   $k=0;
   for($m=0;$m<@raw_hist;$m++){     
      chomp($d=$raw_hist[$m]);     
      next if (exists $ignore_dups{$d});# if a directory exists in static part you do not need it in the dynamic part of the list
      unless(exists $dir{$d}) {
          $history[$k++]=$d; # this is for cd- cd-- cd--- aliases 
      }
      $dir{$d}+=$m; # a very simple fading scheme based on line number implemented Oct 31, 2019 
   }      
   
#
# Generate cd-1 cd-2 type of aliases traversing @history fron the last to the (last -h) element
#
   $h=($#history>7) ? 7 : $#history-1;
   $k=1;
   for ($i=$#history; $i>$#history-$h; $i--) {
      print "alias cd-$k='cd $history[$i]'\n"; # generate aliases cd-1, cd-2  NOTE: History should be indexed by $i, while alias by k
      if( $k<=3 ){
        # only three last directories
        print 'alias cd'.('-' x $k)."='cd $history[$i]'\n"; # generate aliases cd-, cd--  and cd---
      } 
      ++$k;
   }#for

#
# extract for hash %dir max values and put then into @name array
#
   $i=0;
   foreach $n (sort { $dir{$b}<=>$dir{$a}} keys %dir ){
      next unless(-d $n);
      $name[$i++]=$n;        
   }  
# push in reverse order;


   if( $mc_fav_flag ){
      $total=($#name>21) ? 21 : $#name; # this is for mc only 
      if( -d $HOME.'/.config/mc' ){        
         $hotlist=$HOME.'/.config/mc/hotlist';
         if ( open(SYSOUT,'>',$hotlist) ){             
            for( $i=0; $i<@static_fav; $i++ ){
              #ENTRY "/etc" URL "/etc"
              next unless($static_fav[$i]);
              print SYSOUT qq(ENTRY "$static_fav[$i]" URL "$static_fav[$i]"\n); # this is mc format for favories
            } 
            print SYSOUT qq(ENTRY "--------------------------------------" URL "/"\n); # this is mc format for favories
            # Put in reverse order assesible from the bottom
            for( $i=$total; $i>=0; $i-- ){
               next unless($name[$i]);
               print SYSOUT qq(ENTRY "$name[$i]" URL "$name[$i]"\n); # this is mc format for favories          
            }
            close SYSOUT;         
         }else{
           print STDERR "DIR_FAVORITES: Incorrect permissions for $hotlist -- can not write to the file\n\n";
         }         
      }   
   }#$mc_fav_flag  
   
   print "dirs -c > /dev/null\n"; # clean stack 
   # push in reverse order;   
   $total=($#name>7) ? 7 : $#name; # this is pushd only 
   for( $i=$total; $i>=0; $i-- ){
     next if exists($ignore_dups{$name[$i]});
     print "pushd -n $name[$i] > /dev/null\n";
   }

#
# Output static part previously processed
#   
   print "pushd -n /etc > /dev/null # == static ==\n"; # artificial separator 
   for ($i=$#static_fav; $i>=0; $i--) {
     print "pushd -n  $static_fav[$i] > /dev/null\n"; # this is pregenerated push lines
   }
   # write aliases for dir panel
   # open(SYSDIR, ">$HOME/.dir_panel");
   # for ($i=0; $i<$total; $i++)
   #    print SYSDIR "$name[$i]\n";
   # }
   # close SYSDIR;

exit 0;
