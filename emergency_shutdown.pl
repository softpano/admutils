#!/usr/bin/perl
#:: emergency_shutdown -- If a failed hard drive detected by DRAC, sent the notification to active users and then in 23 hours shut down the server
#:: by Nikolai Bezroukov, 2019-2020. Released under Perl Artistic License
#::
#:: The utility logins to DRAC via ssh and issues the command to list of disk state. 
#:: DRAC should be configured for passwordless ssh login. 
#::
#:: The returned results are captured and then analyzed.
#:: If a failed disk found, it schedules the shutdown in specified period (default is five days) and send reminders each day. 
#::
#:: Should be scheduled daily in the morning (to give users more time to backup the most vital files) via cron or /cron/daily
#::
#:: If /etc/paswd comment field contians user email addresses, the utility sends email to users who logged in at least once to the server during the current month plus P months
#:: (specified via option -p, see below). This is done by analyzing utmp log ( via last command). 
#:: For example, the option -p 1 means "the current month plus one month before it" (this is the default)
#::
#:: If /etc/passwd comment field does not contain such addresses or, for example, NIS or LDAP is used, you can block this behaviour by specifing option -e 0 . 
#::
#:: Usage:
#::
#::    emergency_shutdown <options>
#::
#:: Options:
#::   -d -- debug level ( 0 - production;  1 - testing; 2-9 -- debugging )
#::   -h -- this screen
#::   -v -- verbose mode
#::   -p -- number of months before current for collection of user logins via last command
#::         -p 0 means the current month only. The default is -p 1
#::         (the current month plus month before it; two month in total of last log will be analyzed)
#::   -s -- shutdown delay in days (default is 5 days) 
#::   -m -- list of mail recipients separated by comma
#::   -e -- 0 -- /etc/passwd comment field does not contain email of the users; 1 -- /etc/passwd comment field contain email of the users (default -e 1);
#::         in case -e 1 the program will attempt to collect from /etc/passwd email addresses of users 
#::         who login during the period (in months) specified by option -p and send email to all of them. 
#::         format of comment field that should contain email address is arbitrary as long 
#::         as address is separated from other fields by ,(comma) space or ;(semicolon)
#::         For example, all the formats below are OK: 
#::              userj:x:45878:45878:joe.user@firma.com:/L2/users/userj:/bin/bash
#::              userj:x:45878:45878:Joe User,555-444-7799, joe.user@firma.com:/L2/users/userj:/bin/bash
#::              userj:x:45878:45878:Joe User joe.user@firma.com 555-444-7799:/L2/users/userj:/bin/bash
#::         
#--- Development History
#
#++ Ver   Date         Who       Modification
#++ ===   ==========   ========  =========================
#++ 1.00  2019/10/04   BEZROUN   Initial implementation
#++ 1.10  2019/10/07   BEZROUN   Mailing to most recent users added
#++ 1.20  2019/10/08   BEZROUN   Period for which users are extracted can now be specified via option -p 
#++ 1.21  2019/10/09   BEZROUN   In case of abnomal situation log is mailed to primary sysadmin now (defined in /root/primary_admin) 
#++ 1.22  2019/10/10   BEZROUN   More correct treatment of debug flag, if specified in options
#++ 1.30  2020/10/26   BEZROUN   Shutdown extended to 5 days. File with countdown introduced 
#++ 1.31  2020/10/26   BEZROUN   Option -s implemented to specify the number to day to shutdown 
#=========================== START ================================================================================================

   use v5.10;
   use warnings;
   use strict 'subs';
   use feature 'state';
   use Getopt::Std;

   $VERSION='1.31';
   $SCRIPT_NAME='emergency_shutdown';
#
# Parameters defaults
# 
   $debug=0;
   # debug=1 -- development mode --  source code written to archive, which can be managed by GIT
   # debug=2 -- no mailing to list of active users, no execution of shutdown command
   $LoginPeriod=1; # #login period is in months before current (zero means the current month only). Can be set by option -p
   $LOG_RETENTION_PERIOD=365; # log retention period
   $STOP_STRING='';
   $git_repo=''; 
   $user_emails_in_passwd=1;

#
# Constants
#   
  $shutdown_delay_days=5;
  $shutdown_delay=24*$shutdown_delay_days;
  $middle_of_the_month=15; # script should send verification messages even if everything is OK twice a month to see that it is still alive.
                           # if debug>0 it is reset to the current day in epilog code block.

#
# Directories
#
  $HOME=$ENV{'HOME'};
  $LOG_DIR='/var/opt/'.ucfirst($SCRIPT_NAME);
  if( -f "$LOG_DIR/active_users.txt" ){
     unlink("$LOG_DIR/active_users.txt");
  }
  $ReportFile="$LOG_DIR/drive_state.lst";
  chomp($HOSTNAME=`hostname -s`); 

#
# Set default for logme
# 
   banner($LOG_DIR,$SCRIPT_NAME,"Emergency shutdown after disk failure, Version $VERSION",$LOG_RETENTION_PERIOD); # Opens SYSLOG and print STDERRs banner; parameter 4 is log retention period
   get_params();  
  
   if( $debug>0 ){
      out("The program is working in debug mode $debug");
      logme('D',3,3); 
      autocommit("$HOME/Archive",$SCRIPT_NAME,$git_repo)
   }else{
       logme('D',2,2);
   }
   #
# Mail addresses
#
  unless(defined($PrimaryRecipientList)){
    $PrimaryRecipientList=get_primary_admin(); # try to get it iether from /etc/passwd UID 0 field or /root/primary_admin
  }  
   
   
#
# Check if run as root
#
   ( $< > 0 ) && abend("Script should be run as root");
#
#  Get disk health report. If debug>=2 reuse existing one on the disk
#
   if( $debug>1 ){
      if ( -f $ReportFile ) {
        @HealthReport=`cat $ReportFile`;
      }else{
        get_health_report();
      }
   }else{
      get_health_report();
   }

my $i=$failed_disk_no=0;
   while($i<@HealthReport) {
      $header=$HealthReport[$i];
      if (substr($header,0,length('Disk.Bay')) eq 'Disk.Bay' ) {
         $descr=$HealthReport[$i+1];
         $state=$HealthReport[$i+2];
         if ($state=~/Failed/) {
            (undef,$descr)=split(/=/,$descr);
            logme("S","Server $HOSTNAME expirienced failure of disk $descr");
            $problem="Failure of disk: $descr";
            $failed_disk_no++;
         }
         $i+=3;
      }else{
         logme('E',"Loss in syncronicity in line $HealthReport[$i].Resyncronizing");
         $i++;
         next;
      }
   }
   if( $failed_disk_no == 0 ){
      $message="No failed disks detected.\n\n";
      out($message);

      chomp($day=`date +%d`);
      if( $debug > 0 ){
         $middle_of_the_month=$day; # trick to get report in debug mode
      }
      if( $day==1 || $day==$middle_of_the_month ){
         mailme("cat $ReportFile",'INFO',$message);
      }
      logme('T','Normal exit from the program. RC=0');
      exit 0;
   }
   #
   # Collect affected users
   #
   
   if( $failed_disk_no > 1 ){
      $message="RAID5 probably destroyed. Try to save some data without shutting down the server";
      mailme("cat $ReportFile",'$failed_disk_no disks failed',$message);
      abend($message);
   }elsif( -f "$LOG_DIR/countdown.txt" ){ 
      $countdown=`cat $LOG_DIR/countdown.txt`;
      chomp($countdown);
      if( $countdown>24 ){
         $countdown-=24;
         `echo $countdown > $LOG_DIR/countdown.txt`;
         $message="One harddrive in RAID5 array failed and the server will be shutdown down in $countdown hours.";
         mailme("cat $ReportFile",'REMINDER:',$message);
      }else{
         unlink("$LOG_DIR/countdown.txt"); # we no longer need it
         shutdown_procedure(); # set $message and mails it as a side effect
      }   
   }else{
      `echo $shutdown_delay > $LOG_DIR/countdown.txt`;
      $message=" One harddrive in RAID5 array failed and the server will be shutdown down in  $shutdown_delay_days days, or $shutdown_delay hours.";
      mailme("cat $ReportFile",'EMERGENCY SHUTDOWN PLANNED:',$message);
   }
   exit 255;  

#
# ======================== SUBROUTINES ===================================
#
sub get_health_report
{
   @HealthReport=`ssh -l bezroun lusytp100-rm "racadm storage get pdisks -o -p 'DeviceDescription,State'"`;
   if ( $? >0 || scalar(@HealthReport)==0 ) {
      $message="Unable to extract information about hard drives from DRAC";
      #`ls -l $LOG_DIR | mail -s "$mail_prefix $message" $PrimaryRecipientList`;
      mailme("ls -l $LOG_DIR","INTERNAL ERROR",$message);
      abend($message);
   }
   open(SYSOUT,'>',$ReportFile) || abend("Can't write to $ReportFile");
   print SYSOUT @HealthReport;
   close SYSOUT;

}
sub shutdown_procedure
{

#
# Get list of user logins from last command for specifyed by the $login period number on months (0 means curren month)
# Send them mail and schedule shutdown command via at
#
my $k;
my $interval=60*24-10;
my $message="One harddrive in RAID5 array failed and the server will be shutdown down in 24 hours. Save your data ASAP";
#chomp($MONTH_BEFORE_LAST=`date +'%b' -d 'now -2 month'`);
#chomp($LAST_MONTH=`date +'%b' -d 'last month'`);
#chomp($THIS_MONTH=`date +'%b' -d 'now'`);
#print "Range $THIS_MONTH $LAST_MONTH $MONTH_BEFORE_LAST";


   if ($debug) {
      logme('S',"Problem: $problem\nmessage: $message");
   }
   `echo "$problem" > $LOG_DIR/problem.txt`;
   if( $debug == 0 ){      
      mailme("cat $LOG_DIR/problem.txt","EMERGENCY SHUTDOWN IN PROGRESS:",$message);
   }else{
      mailme("cat $ReportFile","SHUTDOWN TEST",$message);
   }
#
# Shutdown the server in 24 hours, You can also cancel shutdowm command with shutdown -c  
#
  $command=qq(echo /sbin/shutdown -h +$interval "$message" | at now);
  out("Generated shutdown command:\n\t$command");
  exit if( $debug > 1); # do not execute shutdowen command 
  
  if ($debug>0) {
     say "Cancel if incorrect in 10 sec. You can also cancel shutdowm command with shutdown -c ";
     sleep 10;
  }

  $protocol=`$command`;
  logme('W',"The output of at command\n$protocol");

} # shutdown_procedure

sub mailme
{
my $create_body=$_[0];
my $mail_prefix=$_[1];
my $message=$_[2];
my $recipients=$_[3];
my ($addr_list,@affected_users,%userbase,@F,$i,$k,$u,$line,$mon,$period,$last_month,$urecord);
   unless( defined($recipients) ){
      $recipients=$PrimaryRecipientList;
   }
   
   if( $debug>0 ){
      $recipients=$PrimaryRecipientList;
   }elsif($user_emails_in_passwd==1){      
      #
      # Add recent users to the mail list 
      #
      @affected_users=`last | grep -v -P "^root|^reboot|^wtmp"`;
      $addr_list='';
      chomp($last_month=`date +'%b' -d 'now'`);
      for ($k=0; $k<@affected_users; $k++) {
         $line=$affected_users[$k];
         $mon=substr($line,length('root     pts/0        10.202.11.115    Fri '),3);
         ($u,undef)=split(/\s+/,$line,2);
         if( exists($userbase{$u}) ){
             next;
         }
         $userbase{$u}=$mon;
         `echo $u >> $LOG_DIR/active_users.txt`;
         
         if ($mon ne $last_month) {
            $period++;
            ( $debug>1 ) && print "Another month $mon\n";
            $last_month=$mon;
            last if ($period>$LoginPeriod);  # $LoginPeriod=1 means two months of lastdata
         }
         if( $u eq 'root' || $u eq 'wtmp' || $u eq 'reboot' ){
            next;
         }else{
            $urecord=`grep -P '^$u' /etc/passwd`;
            if( $? > 0 ) {
               logme('E',"User $u not found. Probably was deleted)");
               next;
            }
            @passwd=split(/:/,$urecord);
            #userj:x:45878:45878:joe.user@firma.com:/L2/users/userj:/bin/bash
            @F=split(/[ ,;]+/,$passwd[4]);
            for($i=0;$i<@F;$i++){
               if( index($F[$i],'@')>0 && $F[$i]=~/\.\w+$/ ){
                  $addr_list.=','.$F[$i];
                  logme('W',"Email address $F[$i] is assumed for the user $u"); 
                  last;
               }
            }   
            if($i>=@F){
               logme('E',"The comment field in /etc/passwd record for user $u does not contain his/her email address.Skipped"); 
            }              
         }
      }#
      $recipients.=$addr_list;
   }

   out(qq(Sending message "$message" to $recipients));
   $listing=`$create_body | mail -s "[$HOSTNAME $mail_prefix] $message" $recipients`;
   if( $? > 0 ){
      logme('S',"Non zero return code from mail command: $?");
      out($listing)
   }
}
#
# Email can be in /root/primary_admin
# or in root record of /etc/passwd
#
sub run
{
my $command=$_[0];
   if ($debug>0) {
      say "GENERATED COMMAND: $command";
   }
   if( $debug==0 ){
     $protocol=`$command`;
     if ($?>0) {
       $rc=$?;
       logme('E',"Command $command return code $rc");
       return $rc
     }
   }
   return 0;
}
sub context
{

}
#
# one parameter -- script owner.
#
sub get_primary_admin
{
   if ( -e "/root/primary_admin" ) {
     chomp($PrimaryRecipientList=`cat /root/primary_admin`);
     if( index($PrimaryRecipientList,':')>-1) {
       ($PrimaryRecipientList, undef)=split(/:/,`cat /root/primary_admin`,2);
     }
     return $PrimaryRecipientList;
   }else{
     $PrimaryRecipientList=`grep -P '^root' /etc/passwd`;
     my @F=split(/:/,$PrimaryRecipientList);
     $PrimaryRecipientList=$F[4];
     if( index($PrimaryRecipientList,'@')>=1 ){
        return $PrimaryRecipientList;
     }else{
        logme('S','Unable to detect email address of primary administrator for the server. Please specify it in option -m, or in the file /root/primary_admin'); 
        exit 255;
     }
   }  
}
#
# process parameters and options
#
sub get_params
{
      getopts("fhrb:t:v:d:p:s:m:",\%options);
      if(  exists $options{'v'} ){
         if( $options{'v'} =~/\d/ && $options{'v'}<3 ){
            logme('D',$options{'v'},);
         }else{
            logme('D',3,3); # add warnings
         }
      }

      if(  exists $options{'h'} ){
         helpme();
      }

      if(  exists $options{'d'}  ){
         if( $debug =~/\d/ ){
            $debug=$options{'d'};
         }elsif( $options{'d'} eq '' ){
            $debug=1;
         }else{
            die("Non numeric value of option -d: $options('d')\n");
         }
      }
      if(  exists $options{'p'} ){
         #login period in months
         if( $options{'p'} =~/\d/ ){
            $LoginPeriod=$options{'p'};
         }else{
            $LoginPeriod=0; # add warnings
         }
      }
       if(  exists $options{'s'} ){
         #shutdown delay in days
         if( $options{'s'} =~/\d/ ){
            $shutdown_delay_days=$options{'s'};
         }else{
             die("Non numberic value of option -s: $options('s')\n");
         }
      }
      if(  exists $options{'m'} ){
         #list of email recipients separated by comma
         if( index($options{'m'},'@')>-1 && $options{'m'}=~/\.+$/ ){
            $PrimaryRecipientList=$options{'m'};
         }else{
             die('Email address does not contain the letter @ or dot: '.$options{'m'}."\n");
         }
      }

}

#
## sp: My SP toolkit subroutines
#
#
# Create backup and commit script to GIT repository if there were changes from previous version.
#
#package sp;
sub autocommit
{
# parameters
my $archive_dir=$_[0]; # typically home or $HOME/bin
my $script_name=$_[1];
my $git_repo=$_[2]; # GIT dir

#
#  commit each running version to the repository to central GIT
#

my $script_timestamp;
my $script_delta=1;
      ( ! -d $archive_dir ) && `mkdir -p $archive_dir`;
      if(  -f "$archive_dir/$script_name"  ){
         if( (-s $0 ) == (-s "$archive_dir/$script_name")   ){
            `diff $0 $archive_dir/$script_name`;
            $script_delta=( $? == 0 )? 0: 1;
         }

         if( $script_delta ){
            chomp($script_timestamp=`date -r $archive_dir/$script_name +"%y%m%d_%H%M"`);
            `mv $archive_dir/$script_name $archive_dir/$script_name.$script_timestamp`;

         }
      }
      if( $script_delta ){
        `cp -p $0 $archive_dir/$script_name`;
        ($git_repo) && `git commit $0`;
      }  
} # autocommit

# Read script and extract help from comments starting with #::
#
sub helpme
{
      open(SYSHELP,"<$0");
      while($line=<SYSHELP> ){
         if(  substr($line,0,3) eq "#::" ){
            print STDERR substr($line,3);
         }
      } # for
      close SYSHELP;
      exit;
}

#
# Terminate program (variant without mailing)
#
sub abend
{
my $message;
my $lineno=$_[0];
      if( scalar(@_)==1 ){
         $message="T$lineno  ABEND at line $lineno. No message was provided. Exiting.";
      }else{
         $message="T$lineno $_[1]. Exiting";
      }
#  Syslog might not be availble
      out($message); 
      close SYSLOG;
      `cat $LogFile | mail -s "[$HOSTNAME ABEND] $message" $PrimaryRecipientList`;
      die($message."\n");

} # abend

#
# Open log and output the banner; if additional arguments given treat them as subtitles
#        depends of two variable from main namespace: VERSION and debug
sub banner {

#
# Decode obligatory arguments
#
my $my_log_dir=$_[0];
my $script_name=$_[1];
my $title=$_[2]; # this is an optional argumnet which is print STDERRed as subtitle after the title.
my $log_retention_period=$_[3];

my $timestamp=`date "+%y/%m/%d %H:%M"`; chomp $timestamp;
my $day=`date '+%d'`; chomp $day;
my $logstamp=`date +"%y%m%d_%H%M"`; chomp $logstamp;
my $script_mod_stamp;
      chomp($script_mod_stamp=`date -r $0 +"%y%m%d_%H%M"`);
      if( -d $my_log_dir ){
         if( 1 == $day && $log_retention_period>0 ){
            #Note: in debugging script home dir is your home dir and the last thing you want is to clean it ;-)
            `find $my_log_dir -name "*.log" -type f -mtime +$log_retention_period -delete`; # monthly cleanup
         }
      }else{
         `mkdir -p $my_log_dir`;
      }

      $LogFile="$my_log_dir/$script_name.$logstamp.log";
      open(SYSLOG, '>'. $LogFile) || abend(__LINE__,"Fatal error: unable to open $LogFile");
      $title="\n\n".uc($script_name).": $title (last modified $script_mod_stamp) Running at $timestamp\nLogs are at $LogFile. Type -h for help.\n";
      out($title); # output the banner
      for( my $i=4; $i<@_; $i++) {
         out($_[$i]); # optional subtitles
      }
      out ("================================================================================\n\n");
} #banner

#
# Message generator: Record message in log and STDIN
# PARAMETERS:
#            lineno, severity, message
# ARG1 lineno, If it is negative skip this number of lines
# Arg2 Error code (the first letter is severity, the second letter can be used -- T is timestamp -- put timestamp inthe message)
# Arg3 Text of the message
# NOTE: $top_severity, $verbosity1, $verbosity1 are state variables that are initialized via special call to sp:: sp::logmes

sub logme
{
#our $top_severity; -- should be defined globally
my $error_code=substr($_[0],0,1);
my $error_suffix=(length($_[0])>1) ? substr($_[0],1,1):''; # suffix T means add timestamp
my $message=$_[1];
      chomp($message); # we will add \n ourselves

state $verbosity1; # $verbosity console
state $verbosity2; # $verbosity for log
state $msg_cutlevel1; # variable 6-$verbosity1
state $msg_cutlevel2; # variable 5-$verbosity2
state @ermessage_db; # accumulates messages for each caterory (warning, errors and severe errors)
state @ercounter;
state $delim='=' x 80;
state $MessagePrefix='';

#
# special cases -- ercode "D" means set msglevel1 and msglevel2, ' ' means print STDERR in log and console -- essentially out with messsage header
#

      if( $error_code eq 'D' ){
         # NOTE You can dynamically change verbosity within the script by issue D message.
         # Set script name and message  prefix
         if ( $MessagePrefix eq '') {
            $MessagePrefix=substr($0,rindex($0,'/')+1);
            $MessagePrefix=substr( $MessagePrefix,0,4);
         }
         $verbosity1=$_[1];
         $verbosity2=$_[2];
         $msg_cutlevel1=length("WEST")-$verbosity1-1; # verbosity 3 is max and means 4-3-1 =0 is index correcponfing to  ('W')
         $msg_cutlevel2=length("WEST")-$verbosity2-1; # same for log only (like in MSGLEVEL mainframes ;-)
         return;
      }
      unless ( $error_code ){
         # Blank error code or 'I' are old equivalent of out: put obligatory message on console and into log
         out($message);
         return;
      }
#
# detect callere.
#
      my ($package, $filename, $lineno) = caller;
#
# Generate diagnostic message from error code, line number and message (optionally timestamp is suffix of error code is T)
#
      $message="$MessagePrefix\-$error_code$lineno: $message";
      my $severity=index("west",lc($error_code));
      if( $severity == -1 ){
         out($message);
         return;
      }

      $ercounter[$severity]++; #Increase messages counter  for given severity (supressed messages are counted too)
      $ermessage_db[$severity] .= "\n\n$message"; #Error history for the ercodes E and S
      return if(  $severity<$msg_cutlevel1 && $severity<$msg_cutlevel2 ); # no need to process if this is lower then both msglevels
#
# Stop processing if severity is less then current msglevel1 and msglevel2
#
      if( $severity < 3 ){
         if( $severity >= $msg_cutlevel2 ){
            # $msg_cutlevel2 defines writing to SYSLOG. 3 means Errors (Severe and terminal messages always whould be print STDERRed)
            if( $severity<2 ){
               print SYSLOG "$message\n";
            } else {
               # special treatment of serious messages
               print SYSLOG "$delim\n$message\n$delim\n";
            }
         }
         if( $severity >= $msg_cutlevel1 ){
            # $msg_cutlevel1 defines writing to STDIN. 3 means Errors (Severe and terminal messages always whould be print STDERRed)
            if( $severity<2 ){
               print STDERR "$message\n";
            } else {
               print STDERR "$delim\n$message\n$delim\n";
            }
         }
         if (length($::STOP_STRING)>0 && index($::STOP_STRING,$error_code) >-1 ){
            $DB::single = 1;
         }
         return;
      } # $severity<3
# == Severity=3 -- error code T
#    Here we processing error code 'T' which means "Issue error summary and normally terminate"
#   

my $summary='';

      #
      # We will put the most severe errors at the end and make 15 sec pause before  read them
      #
      out("\n$message");
      for( my $counter=1; $counter<length('WES'); $counter++ ){
         if( defined($ercounter[$counter]) ){
            $summary.=" ".substr('WES',$counter,1).": ".$ercounter[$counter];
         }else{
            $ercounter[$counter]=0;
         }
      } # for
      ($summary) && out("\n=== SUMMARY OF ERRORS: $summary\n");
      if( $ercounter[1] + $ercounter[2] ){
         # print STDERR errors & severe errors
         for(  $severity=1;  $severity<3; $severity++ ){
            # $ermessage_db[$severity]
            if( $ercounter[$severity] > 0 ){
               out("$ermessage_db[$severity]\n\n");
            }
         }
         ($ercounter[2]>0) && out("\n*** PLEASE CHECK $ercounter[2] SERIOUS MESSAGES ABOVE");
      }

#
# Compute RC code: 10 or higher there are serious messages
#
      my $rc=0;
      if( $ercounter[2]>0 ){
         $rc=($ercounter[2]<9) ? 10*$ercounter[2] : 90;
      }
      if( $ercounter[1]>0 ){
         $rc=($ercounter[1]<9) ? $ercounter[2] : 9;
      }
      exit $rc;
} # logme

#
# Output message to both log and STDERR
#
sub out
{
      if( scalar(@_)==0 ){
         say STDERR;
         say SYSLOG;
         return;
      }
      say STDERR $_[0];
      say SYSLOG $_[0];
}

sub step
{
      $DB::single = 1;
}