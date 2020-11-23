#!/usr/bin/bash
# Intelligent cd. 
#
# Copyright Nikolai Bezroukov 2007-2020
# Licensed under the original BSD license
#
# It is minimal not to screw up the things.  
# Displays dirs stack and allow tro select an entry; or expand supplied string into a path to directory according to rules descibed below
#
# 1. If no parameters given displays dirs stack and allow to to provide a reply string which can be a number or string 
#    a. If the reply is the bumber selects the directory from dirs stack with this number counting from top 
#       For countring from the bottom the number should be prefixed by minus
#    b. If the reply is string that does not contain / invokes fcd function and expland it into path to the directory according to rules (2) and (3) below
#    c. If the reply contains / execute rregular cd command with this parameter. 
#    
# 2. if one parameter is given, it is split into letters and asterisks and slashes put in between 
#    For example, 
#        go ulb 
#    is equivalent to 
#        cd /u*/l*/b*
#
# 3. If multiple parameters are given they are concateneted with */
#    For example 
#       go use loc bi 
#    is equvalent to 
#       cd /use*/loc*/bi*
#
# NOTE: Functionality of dir_favorites.pl exlained elsewhere. Type dir_favirites.pl -h for help. 
#
#-------------------------------------------------------------------------------------------  
# Ver      Date        Who        Modification
# ====  ==========  ========  ==============================================================
# 0.10  2007/01/02  Bezroun   Initial implementation 
# 0.20  2008/05/16  Bezroun   fcd function added, which in a non-obious way to imitate ncd. 
# 0.30  2008/06/01  Bezroun   dir_favorites is now integrated
# 0.40  2009/09/10  Bezroun   generation now includes aliases cd-- cd-- and cd-3
# 1.00  2020/11/19  Bezroun   .config is now used for static favorites and temp files
# 1.10  2020/11/23  Bezroun   Polishing before publishing 
  
#---------------------------------------------------------------
function go {
   if (( $# > 0 )); then 
      fcd $@
      return
   fi   
    
   perl $HOME/bin/dir_favorites.pl -m > $HOME/.config/dir_current.tmp 
   . $HOME/.config/dir_current.tmp
   dirs -v
   echo -n 'Select favorite (postive counting from top, negative from bottom) or copy the path: '
   read target
   echo $target
   if [[ $target =~ '/' ]]; then 
      #echo absolute
      cd $target
   else
      #echo numeric 
      if (( target < 0 )); then
         echo $target
         mydir=`dirs -l $target`
         cd $mydir
      elif (( target > 0 )); then
         echo +$target
         mydir=`dirs -l +$target`
         cd $mydir
      fi   
   fi   
   
}
#
# Writes current dir into DIRHISTORY
#
function my_prompt
{
   local EXIT_STATUS=$?
   if [ ! -d "$HOME/.config" ] ; then
      mkdir -p "$HOME/.config"
   fi
   # should be executed on each command for writing history to the file if you have multiple terminals open. 
   history -a #Append the history lines entered since the beginning of the current Bash session to the history file. 
   history -c #clean history 
   history -r #reread from the file
   pwd >> "$HOME/.config/dir_history"
   history 1 >> $HOME/.bash_eternal_history #  # attempt to deal with multiple session, which do not write to history -- NNB, Oct 27, 2019. 
   color_yellow="\[\e[33;40m\]"
   color_red_bold="\[\e[31;1m\]"
   color_blue_bold="\[\e[34;1m\]"
   color_none="\[\e[0m\]"
   echo `date +"%y/%m/%d %H:%M:%S"` "$PWD ============================$HOSTNAME" 
   local ps1_status ps1_user_color       
               
   if (( $EXIT_STATUS != 0 )); then
       ps1_status="${color_yellow}[$EXIT_STATUS]${color_none} "
   else
       ps1_status="[0]"
   fi
                                             
   if [[ `whoami` = "root" ]]; then
      ps1_user_color=${color_red_bold}
    else
      ps1_user_color=${color_blue_bold}
   fi
   # export PROMPT_DIRTRIM=3 control number of directories to disply in PS1 \w                                                             
   local name=`hostname -s`
   PS1="${ps1_status}${ps1_user_color}\\u@$name:${color_none} \\$ "
   
   mod=$(( `date +%s` % 5 ))
   if (( $mod == 0 )) ; then  
      #echo Updating favorites each time we have  number of sec divisible by 5
      perl $HOME/bin/dir_favorites.pl -m > $HOME/.config/dir_current.tmp; . $HOME/.config/dir_current.tmp      
   fi
}
#----------------------------- ncd imitation
# Provide short one letter abberiation and long multiletter abbreviation separated by space
function fcd 
{
local STRING=$1
local NEWDIR=''
   if (( $# == 1 )); then
      local i=0
      LIMIT=${#STRING}
      while (( $i < $LIMIT ))
      do
         s=${STRING:$i:1}
         NEWDIR="$NEWDIR/$s*"
         (( i += 1 ))
      done
      
   else
      # concat fragments and append start to them 
      for d in $@ ; do
        if [[ $NEWDIR == '' ]]; then 
            NEWDIR=/$d
        else     
            NEWDIR="$NEWDIR*/$d"
        fi    
      done
      NEWDIR="$NEWDIR*" # add last asterisk
   fi 
   echo cd $NEWDIR
   builtin cd $NEWDIR
     
}