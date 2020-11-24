!/usr/bin/perl
#:: dir_favorites.pl -- process favorites and create aliases for the most used directories
#:: Copyright Nikolai Bezroukov 2007-2020. Licensed under the original BSD license
#::
#:: The utility creates a history of accessed directories and a set of aliases such as cd--, cd---, cd-4...
#:: It requires the usage of custom prompt function (provided as my_prompt in dir_favorites_shell_functions.sh.) 
#:: which should be referenced in .bash_profile/.bashrc as:
#::              export PROMPT_COMMAND='my_prompt'
#::
#:: Favorites are stored in Bash directory stack accessible by dirs command.
#::
#:: Generated list of directory favorites consists of two parts -- static (loaded from a file  $HOME/.config/dir_favorites.$HOSTNAME ) 
#:: and dynamic (created directly from the history of visited directories ). 
#::
#:: The utility also dynamically generates aliases extending cd - capabilities such as cd--, cd---, cd-4, cd-5 and so on
#::
#:: It is intended to be used not directly but via function go, which is also provided in dir_favorites_shell_functions.sh
#::
#::--- INVOCATION 
#::    . ~/bin/dir_favorites_shell_functions.sh
#::    go
#:: NOTE: Generally it is recommended to move the command export PROMPT_COMMAND='my_prompt' to .bash_profile/.bashrc
#::
#:: If it is invoked with option -m the utility also changes directory favorites in MC (Midnight commander) providing dynamic updates. 
#:: Like with directory favorites accessible via function go, mc hotlist consist of two parts -- static and dynamic, 
#:: but the dynamic part is larger (21 entry)
#::
#:: The static list of favorites is stored in the file $HOME/.config/dir_favorites.$HOST and can be modified using mcedit. 
#::
#:: I recommend to create two functions (for example f, F) with one adding the current directory to the static list of directory favorites
#:: and another evoking mcedit on static favorite list, allowing to edit it from within MC. 
#::
#--- Development History
#
# Ver      Date        Who        Modification
# ====  ==========  ========  ==============================================================
# 1.00  2007/07/02  Bezroun   Initial implementation
# 2.00  2008/09/16  Bezroun   Alias generation added
# 3.00  2013/04/17  Bezroun   Pipe is replaced with internal processing
# 4.00  2019/10/19  Bezroun   Integration with Midnight Commander added
# 4.10  2019/10/30  Bezroun   Some errors corrected. Logic improved
# 4.20  2019/10/31  Bezroun   Fading of favorites based on line number implemented; older frequently used directory now have less weight 
# 4.21  2019/10/31  Bezroun   Empty entries are now excluded. History is limited to the last 1000 lines. 
# 4.30  2019/11/07  Bezroun   Comments in static favorites in MC are allowed 
# 4.40  2020/11/18  Bezroun   Method of sorting the directory history changes and the logic revised.
# 4.50  2020/11/19  Bezroun   Midnight command favorites generation now is optional (you need to specify option -m to enable it)
# 4.51  2020/11/23  Bezroun   Correction for the generation of cd-, cd--, cd---,cd-4, cd-5...aliases
# 4.52  2020/11/24  Bezroun   Help screen added accesible via dir_favorites.pl -h 
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
   if ( scalar(@ARGV)>0 ){
     if( $ARGV[0] eq '-m' ){
        $mc_fav_flag=1;
     }elsif(  $ARGV[0] eq '-h' ){ 
        helpme();
     }   
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
      if( $k<=3 ){
        # only three last directories. NOTE: History should be indexed by $i, while alias by k
        print 'alias cd'.('-' x $k)."='cd $history[$i]'\n"; # generate aliases cd-, cd--  and cd---
      }else{
         print "alias cd-$k='cd $history[$i]'\n"; # generate aliases cd-4, cd-5...  
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

sub helpme
#print help screen 
{
   open(SYSHELP,'<',$0);
   while($line=<SYSHELP>) {
      if ( substr($line,0,3) eq "#::" ) {
         print substr($line,3);
      }
   } # for
   close SYSHELP;
   exit 0;
}
