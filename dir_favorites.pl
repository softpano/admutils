#!/usr/bin/perl
#:: dir_favorites.pl -- process favorites and create aliases for the most used directories
#:: Copyright Nikolai Bezroukov 2007-2020. Licensed under the original BSD license
#::
#:: The utility creates a history of accessed directories and a set of aliases such as cd--, 3rb (for root/bin),  
#:: 2esn for /etc/sysconfig/network-scripts. You got the idea. 
#::
#:: It requires the usage of custom prompt function (provided as my_prompt in included in the distrinution file dir_favorites_shell_functions.sh)  
#:: which should be referenced in .bash_profile/.bashrc as:
#::      export PROMPT_COMMAND='my_prompt'
#::
#:: The second function that uses this utility is function go ( also provided in dir_favorites_shell_functions.sh). It displayed list of directories 
#:: and allows to cd to any of them by putting the number of copying and editing the path. For example: 
#::     [0]root@lustwz99: # go
#::     0 ~/.config
#::     1 ~/bin
#::     2 ~/.config
#::     3 /etc/sysconfig
#::     4 /etc/sysconfig/network-scripts
#::     5 /etc/profile.d
#::     6 /var/log
#::     7 /etc     --- the divider between static part and dynamic part of favorites; directors below are generated dynamically from the history
#::     8 /tmp/rhel
#::     9 /tmp/rhel/isolinux
#::   10 /mnt/Packages
#::      ... ... ... ..
#::    Select directory by the number (negative from bottom) or copy and edit the path:
#:: 
#:: Favorites are stored in Bash directory stack accessible by dirs command. 
#::
#:: Generated list of directory favorites consists of two parts -- static (loaded from a file $HOME/.config/dir_favorites.$HOSTNAME ) 
#:: and dynamic (created directly from the history of visited directories ). #::
#::
#:: It is intended to be used not directly but via function go, which is also provided in dir_favorites_shell_functions.sh
#:: The utility also dynamically generates aliases extending cd - capabilities. It created the alias cd-- which many sysadmins are missing and 
#:: is set of alias, called "2abbreviations" for each of the directory displayed by go function consisting of the first letters in the path are generated.
#::
#:: So, if the directory /root/bin is present in either static, or dynamic part(they are delimited by /etc entry) of the list displayed by go function, 
#:: you can cd to this directory using the generated alias 
#::      2rb
#:: Those aliases are especially valuable for static part of the directory favorites and they really help to navigate the filesystem 
#::
#::--- INVOCATION
#::
#:: . ~/bin/dir_favorites_shell_functions.sh
#:: go
#::
#:: NOTE: Generally it is recommended to move this commands( which includes export PROMPT_COMMAND='my_prompt' to .bash_profile/.bashrc. 
#:: Or separately into .bashrc and .functions, if you use this configuration. 
#::
#:: If this utility is invoked with option -m it also automatically generates the directory favorites for MC (Midnight commander)  
#:: Like with directory favorites accessible via function go, mc hotlist consist of two parts -- static and dynamic, 
#:: but the dynamic part is larger. They are accessible in mc via ctrl-\
#::
#:: The static list of favorites is stored in the file $HOME/.config/dir_favorites.$HOST ($HOST extention is used in case your home directory 
#:: is on NFS and is accesble from multiple servers) and can be modified using mcedit.  
#::
#:: I recommend to create in MC user menu two entries (for example f, F) with one adding the current directory  to the static list
#:: of directory favorites and another evoking mcediton static favorite list, allowing to edit it from within MC. 
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
# 4.60  2020/11/25  Bezroun   Two optimizations: (1)if directory unchanged end processing; (2) if history is less 2000 entries do not truncate it
# 4.70  2020/12/07  Bezroun   Now we will write to the file $HOME/.config/dir_current.sh instead of STDOUT
# 5.00  2020/12/08  Bezroun   Now instead of cd--- type of alises, "2abbreviations" consisting of the first letters in the path are generated. 
# 5.10  2020/12/09  Bezroun   Documentation improved and changed to reflect version 5 functionality.  
#=================================================================================================================================================
#use v5.10.1;
#use warnings;
#use strict 'subs';

   $VERSION='5.10'; 
   $debug=0;
   $HOME=$ENV{'HOME'};
   chomp($HOST=`hostname -s`);
   %ignore_dups=($HOME=>1,'/etc'=>1,'/'=>1); # exclude HOME; /etc/is used as separator between static part and dynamic part
   $mc_fav_flag=0; # midnight commande favorites generation flag 
   $dir_hist_file="$HOME/.config/dir_history";
   $dir_favorites="$HOME/.config/dir_favorites.$HOST";
   $generated_script="$HOME/.config/dir_current.sh";
#   
# Simplified options parsing
#
   while( scalar(@ARGV)>0 && substr($ARGV[0],0,1) eq '-' ){
      if( $ARGV[0] eq '-m' ){
         $mc_fav_flag=1;         
      }elsif(  $ARGV[0] eq '-h' ){ 
         helpme();
      }elsif(  $ARGV[0] eq '-d' ){ 
         $debug=1;                   
      }else{
         print "Wrong option $ARGV[0]\n\n";
         helpme();
      }
      shift(@ARGV);  
   }
#
# if arguments present slurp them 
#
   if (scalar(@ARGV)>0) {   
      $dir_favorites=shift(@ARGV);
      if (scalar(@ARGV)>0) {
         $generated_script=$ARGV[0]; # this might break go function as well as my_prompt unless they are corrected too 
      }
   }
   
#
# Process static favorite list; create exclution array so that those directories did not clutter the list of frequently used directores (%ignore) 
# 
   
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
   unless (-f $dir_hist_file) { die("File $dir_hist_file does not exits\n") }
   
   open (SYSIN,'<',$dir_hist_file) || die("Can't open $dir_hist_file for reading\n"); 
   $k=0;
   while( $raw_hist[$k++]=<SYSIN> ){};
   
   #if( scalar(@raw_hist)<=3 || $raw_hist[-3] eq $raw_hist[-2] ) -- now do not need that -- done in my_prompt
    
 #  
 # Cut directory history to the last 1K lines if it exceeds 2K lines  
 #
   if(scalar(@raw_hist)>2000){
      # we need to rewrite dir histrory truncating it 
      splice(@raw_hist,0,scalar(@raw_hist)-1000); # tail of last 1K lines
      open(SYSOUT,'>',$dir_hist_file) || die("Can't open $dir_hist_file for writing\n");
      print SYSOUT @raw_hist;
      close SYSOUT;
   }      
   $k=0;
   for( $m=$#raw_hist; $m>=0; $m-- ){  
      next unless($raw_hist[$m]);  
      chomp($d=$raw_hist[$m]); 
      next unless($d);      
      if( scalar(@history)<=21 ){
          $history[$k++]=$d; # this is for cd-- and '2' aliases 
      }
      next if (exists $ignore_dups{$d});# if a directory exists in static part you do not need it in the dynamic part of the list 
      $dir{$d}+=$m; # a very simple fading scheme based on line number implemented Oct 31, 2019 
   }      
   
#
# Generate alias cd-- and 2 type of aliases traversing @history 
#
   open( SYSOUT, '>', $generated_script ) || die("Can't open $generated_script for writing\n\n");
   out( "alias cd--='cd $history[2]'"); # cd-- defines directy accessed before last (0 -cuurent 1 prev(cd -), 2 prev-prev 9cd--)  
   push(@history,@static_fav);
   for( $i=0; $i<@history; $i++ ){        
       @F=split(qr[/],substr($history[$i],1));
       $abbr='2';
       for($k=0; $k<@F; $k++){
          $abbr.=substr($F[$k],0,1);
       }
       next if exists($abbr_db{$abbr});
       $abbr_db{$abbr}=1;
       out( "alias $abbr='cd $history[$i]'"); # 2 type of alias  
   }#for

#
# extract for hash %dir max values and put then into @name array
#
   $i=0;
   foreach $n (sort { $dir{$b}<=>$dir{$a}} keys %dir ){
      next unless(-d $n);
      next if exists($ignore_dups{$n});
      $name[$i++]=$n;        
   }  
# push in reverse order;    
   out( "dirs -c > /dev/null"); # clean stack 
   # push in reverse order;   
   $total=($#name>12) ? 12 : $#name; # this is pushd only 
   for( $i=$total; $i>=0; $i-- ){
      out( "pushd -n $name[$i] > /dev/null");
   }

#
# Output static part previously processed
#   
   out("pushd -n /etc > /dev/null # == static =="); # artificial separator 
   for ($i=$#static_fav; $i>=0; $i--) {
      out("pushd -n  $static_fav[$i] > /dev/null"); # this is pregenerated push lines
   }
   close SYSOUT;
   
   if( $mc_fav_flag && -d $HOME.'/.config/mc' ){
      $total=($#name>21) ? 21 : $#name; # this is for mc only            
      $hotlist=$HOME.'/.config/mc/hotlist';
      if ( open(SYSOUT,'>',$hotlist) ){             
         for( $i=0; $i<@static_fav; $i++ ){
           #ENTRY "/etc" URL "/etc"
           next unless($static_fav[$i]);
           out(qq(ENTRY "$static_fav[$i]" URL "$static_fav[$i]")); # this is mc format for favories
         } 
         out(qq(ENTRY "--------------------------------------" URL "/")); # this is mc delimiter for dynamic part of favories
         # Put in reverse order accesible from the bottom
         for( $i=$total; $i>=0; $i-- ){
            next unless($name[$i]);
            out(qq(ENTRY "$name[$i]" URL "$name[$i]")); # this is mc format for favories          
         }
         close SYSOUT;         
      }else{
        print STDERR "DIR_FAVORITES: Incorrect permissions for $hotlist -- can not write to the file\n\n";
      }         
         
   }#$mc_fav_flag
sub out
{
   print SYSOUT $_[0],"\n";
   ($debug) && print $_[0],"\n";
}
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
