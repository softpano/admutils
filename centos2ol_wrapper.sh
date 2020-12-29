#!/bin/bash
# centos2ol_wrapper -- Wrapper with sanity checks for centos2ol
# Copyright Nikolai Bezroukov, 2020. Licensed under Perl Artistic license.
#:: 
#:: The script accepts options -d, -b -p, -r (other than -h which print this help screen and -v for verbose output)
#:: You can also adapt configuration parameters that set defaults for those options 
#:: See  http://www.softpanorama.org/Commercial_linuxes/Oracle_linux/conversion_of_centos_to_oracle_linux.shtml for details
#:: 
#:: OPTIONS
#::
#::    -b BASE directory -- directory for backup and temp files 
#:: 
#::    -v -- produces trace of script execution by setting bash -x option 
#::
#::    -r -- change the root password to new value before invoking centos2ol.sh script. 
#::          if the length of the provided password less than 6, the default password centos2p is used. 
#::          So -r 1 is equivalent to -r centos2p. 
#::          This option is important in mass conversions. The situations when the conversion process 
#::          runs into troubles and you do not know the root password (ssh does not work) are no uncommon 
#::
#::    -p -- proxy. For example -p www-proxy.mycompany.com 
#::
#::    -d -- debug mode
#::          0 -- Production mode in which centos2ol is launched from the wrapper. This is the default.
#::          1 -- Testing mode. Any value above zero blocks execution of centos2ol script and 
#::               enables automatic saving of the script in the $HOME/Archive directory
#::               if the source was changed since the last invocation. 
#::          2 -- Same as -d 1 but activates tracing via bash option -x (like option -v does) 
#::
#:: PARAMETERS
#::
#::    1. path_to_centos2ol_script -- The fully qualified name of the conversion script(with path). 
#::                                   The default is /root/bin/centos2ol.sh
#:: 
#::       For example, the invocation
#::
#::             ./centos2ol_wrapper -r -d 0 /tmp/centos2ol_plus.sh
#::
#::       will use /tmp location for the script centos2ol_plus.sh (assumed to be a modified version of  
#::       the original centos2ol.sh script) 
#::
# HISTORY
#
# 1.0 bezroun 2020/12/21  Initial implementation
# 1.1 bezroun 2020/12/21  Added options -b -r -p and -v 
# 1.2 bezroun 2020/12/28  Simple backup of critical file added and option -b to speiocfy path 
# 1.3 bezroun 2020/12/29  Added primitive CMS capabilities for GIT
# 1.4 bezroun 2020/12/29  Conversion script to use is now a parameter, for example centos2ol_plus.sh 
# --------------------------------------------------------------------------------------------------

   debug=0
   set -u 
   SCRIPT_NAME=centos2ol_wrapper
   VERSION='1.4'
   
#
# Configuration parameters -- should be adapted for the particular installation.  
#   
   BASE=/var/Centos2ol_recovery       # Basic recovery data for the server (/etc, /boot and selected part of /root and /var ) 
   CENTOS2OL='/root/bin/centos2ol.sh' # the name of the scipt to execute convertion to Oracle Linux (can be modified one) 
   password='centos2p'                # default root password to reset if option -r is specified with less than 6 characters. 
   set_proxy=0                        # should we set proxy by default ? 
   PROXY='www-proxy.basf-corp.com:8081'  # default proxy to be used

function save_source
{   
   if (( debug )); then
      script_delta=1
      if [[ -f "$HOME/Archive/$SCRIPT_NAME" ]] ; then
         size1=`stat --format=%s "$HOME/$SCRIPT_NAME"`
         size2=`stat --format=%s "$HOME/Archive/$SCRIPT_NAME"`
         if (( $size1 == $size2 )) ; then
            diff $HOME/$SCRIPT_NAME $HOME/Archive/$SCRIPT_NAME
            if (( $? == 0 )) ; then
               script_delta=0;
            fi
         fi
         if (( $script_delta > 0 )) ; then
            SCRIPT_TIMESTAMP=`date -r $HOME/Archive/$SCRIPT_NAME +"%y%m%d_%H%M"`
            mv $HOME/Archive/$SCRIPT_NAME $HOME/Archive/$script.$SCRIPT_TIMESTAMP.sh
            cp -p $HOME/$SCRIPT_NAME $HOME/Archive/$SCRIPT_NAME
         fi
      else
         cp -p $HOME/$SCRIPT_NAME $HOME/Archive/$SCRIPT_NAME
      fi
   fi
}

function step_info
{
   echo
   echo
   echo "============================================================================"
   echo "*** LINE $1, STEP: $2"
   echo "============================================================================"
   sleep 3
}

function info
{
   echo 
   echo "INFO-$1: $2"
   echo
   sleep 3    
}

function abend
{
   echo
   echo "============================================================================"
   echo " !!! Abend at line $1: $2"
   echo "============================================================================"
   echo
   if (( $1 < 255 )); then exit $1;  fi 
   exit 255          
}

#
# Banner
#
   echo
   echo === $SCRIPT_NAME.sh Wrapper with sanity checks for centos2ol. Version $VERSION. Type $SCRIPT_NAME.sh -h for help.
   echo
     while getopts "hvd:b:r:" opt; do
      # echo opt=$opt
      case "$opt" in
      h)
         egrep '^#::' $0 | cut -c 4-
         exit 0
         ;;
         
      v) verbose=1
         info $LINENO "Tracing flag -x was set"
         set -x
         ;;
         
      d) debug=$OPTARG
         echo debug flag is set to $debug
         if (( $debug > 2 )) ; then
            echo Wrong value of -d option. Can be 0, 1, or 2
            exit 16
         elif (( $debug == 0 )) ; then
            info $LINENO "ATTENTION: the script is running in production mode and will invoke centod2ok.sh script"
            echo
         fi
         
         if (( debug > 1 )); then  
            info $LINENO "Tracing flag -x was set"         
            set -x
         fi   
         ;;
         
      b) BASE=$OPTARG
         info $LINENO "Recovery directory set to %BASE"
         ;;
         
      p)  set_proxy=1
          if (( ${#OPTARG} < 6 )); then
           info $LINENO "The length of suplied with option -p argument is less then six. The default proxy assumed"        
         else
           PROXY=$OPTARG
           info $LINENO "Proxy PROXY will be used for both http and https"
         fi
         ;;
   
      r) if (( ${#OPTARG} < 6 )); then
           info $LINENO "The length of suplied with option -r argument is less then six. The root password reset to the default value"         
           password=$OPTARG
         fi 
         info $LINENO "Resetting root password to temporary value $password. In case of troubles simple root password is preferable to the forgotten one"
         echo 'root:password' | chpasswd 
         ;;  
         
      *) echo Wrong option $opt
         exit 16
         ;;
      esac
   done
   shift $((OPTIND-1))
   
   (( debug )) && save_source
   
   if (( $# == 1 )) ; then
      CENTOS2OL=$1
      info "Script $1 will be used for conversion"
   elif (( $# > 1 )) ; then
      abend "Wrong number of arguments -- it should either only one -- the fully qualified (with path) name for the conversion script"
   fi

#
# Processing started 
#
   step_info $LINENO "checking for effective uid"
   effective_uid=`id -u`
   if (( effective_uid > 0 )); then 
       abend $LINENO "You need to run the script as root..."
   fi     

#
# Was script centos2os.sh already run?
#
   oracle_repo_present=`ls /etc/yum.repos.d | grep oracle | wc -l`

   if (( oracle_repo_present > 0 )); then  
      info $LINENO "Oracle repositories were found in /etc/yum.repos.d"
      ls -l /etc/yum.repos.d
      abend $LINENO "Script centos2os.sh was not designed to run twice of the same server. It can destory it if run twice..."
   fi 
#
# Prepering yum for convertions
#
   step_info $LINENO "Cleaning yum"
   yum clean all
   rpm -qa > $BASE/list_of_installed_rpms
   
#
# Creating backup directory
#
   step_info $LINENO "Making backup of vital data"
   if [[ ! -d $BASE ]]; then
      mkdir $BASE;
      if [[ -d $BASE ]]; then
         info $LINENO "[OK] Backup directory $BASE was created sucessfully."
      else
         abend $LINENO "Unable to create the directory $BASE. Are you running the script as Root?"
      fi 
#
# Parcial back in case of troubles you can benefit from a full backup of /etc and /boot and parcial of /var 
#  
      step_info $LINENO "Creating backup of /etc"
      tar cf $BASE/etc_before_conversion.tar -C /etc . 
      step_info $LINENO  "Creating backup of /boot"      
      tar cvzf $BASE/boot_before_conversion.tgz -C /boot .
      sleep 3
      step_info $LINENO  "Creating backip of /root"
      tar cf $BASE/root_dot_files.tar -C /root anaconda-ks.cfg .bash_profile .bashrc .bash_history
      tar cf $BASE/selected_var_cron.tar -C /var/spool/cron .
      tar czf $BASE/var_messages.tgz -C /var/log .     
      echo "[OK] The parcial backup done"
      cd
   else
      info $LINENO "ATTENTION: it looks like this script was already lauched at least once: directory $BASE is present of the server"
   fi      

#
# Checking for extra repositories 
#
   step_info $LINENO  "Checking for extra repositories"
   centos_repo_no=`ls /etc/yum.repos.d | grep CentOS | wc -l`
   if (( centos_repo_no == 0 )); then
       rhel_repo_no=`ls /etc/yum.repos.d | grep redhat | wc -l`
       if (( rhel_repo_no == 0 )); then
          abend $LINENO "/etc/yum.repos.d does not contain a single CentOS or redhat repo"
       fi
       repotag='redhat'
       info $LINENO "[OK] Red hat repostories found in ls /etc/yum.repos.d"
   else
      repotag='CentOS'
      info $LINENO "[OK] CentOS repostories found in ls /etc/yum.repos.d"
   fi       
   extra_repo=`ls /etc/yum.repos.d | grep -v $repotag | wc -l`   
   if  (( extra_repo > 0 )); then 
     step_info $LINENO "You need to eliminate extra repositories from /etc/yum.repo.d The list includes:"
     
     ls /etc/yum.repos.d | grep -v $repotag
     cd /etc/yum.repos.d && ls /etc/yum.repos.d | grep -v $repotag | xargs /bin/rm 
     extra_repo=`ls /etc/yum.repos.d | grep -v $repotag | wc -l`
     if (( extra_repo > 0 )); then 
        abend $LINENO "Unable to eliminate extra repositories. Please do it manually"
      fi
   fi

#If /boot is  mount points,  check for free space. On some appliances /boot is 200M or 500 M and may contain several updated kernels
# so there is no space for the new one

   is_mounted=`mount | fgrep ' /boot type ' | wc -l`
   if (( is_mounted > 0 )); then 
      step_info $LINENO "Checking for 100MB of free space in /boot"
      free_space=`df -m  /boot | tail -1 | tr -s ' ' | cut -d ' ' -f 4`
      if (( free_space < 100 )); then 
         info $LINENO "/boot partition has less then 100MB of free space" 
         df -h /boot
         abend $LINENO "Please free space in /boot manually"
      else
         info $LINENO "[OK] The /boot partition has $free_space megabytes of free space"
      fi   
   fi

   if [[ -d $HOME/.proxy ]]; then 
      step_info $LINENO "Exporting http_proxy and https_proxy from $HOME/.proxy"
      . $HOME/.proxy 
      env | fgrep proxy
   fi   
   
   if (( set_proxy )); then 
      export http_proxy="$PROXY"
      export https_proxy="$PROXY"
   elif [[ -d $HOME/.proxy ]]; then 
      . $HOME/.proxy 
      env | fgrep proxy
   fi    
   
   if (( debug == 0 )); then 
     step_info $LINENO "Staring CENTOS2OL script. Log is at /root/centos2ol.`hostname -s`.log"
     bash -x $CENTOS2OL  | tee /root/centos2ol.`hostname -s`.log
   fi          