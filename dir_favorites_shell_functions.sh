#!/usr/bin/bash
# Last modified Oct 19, 2020
# Ver      Date        Who        Modification
# ====  ==========  ========  ==============================================================
# 1.00  2020/11/19  Bezroun   .config is now used 
#---------------------------------------------------------------
# Intelligent go. It is minimal not to screw up the things. Normally you can use fav. 
#---------------------------------------------------------------
function go {
   perl $HOME/bin/dir_favorites.pl -m > $HOME/.config/dir_current.tmp 
   . $HOME/.config/dir_current.tmp
   dirs -v
   echo -n 'Select favorite (postive counting from top, negative from bottom): '
   read target
   if (( target < 0 )); then
      echo $target
      mydir=`dirs -l $target`
      cd $mydir
   elif (( target >=0 )); then
      echo +$target
      mydir=`dirs -l +$target`
      cd $mydir
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