# Softpanorama collection of potentially useful sysadmin utilities


This project is about publishing of a set of written by me over the years sysadmin utilities (this plan subject to change without notice).

**NOTE**: This page is not maintained often, as I prefer HTML to Markup. See html version of this page at http://softpanorama.org/Admin/Sp_admin_utils/index.shtml for more recent and complete information.

## History

**Dec 28, 2020** *centos2ol_wrapper* Wrapper with sanity checks for centos2ol.sh CentOs to Oracle Linux convertion script. It incorporates several "no nonsense" checks that make success of the conversion more probable. I experienced around 30% failure rate iin my tests and 10% (or one server out of ten failed to report after the conversion was finished). Serious troubles include but not limited to  deletion of hundreds of vital RPMs ( due to my mistake made out  of frustration; nit stll no protection from this kind  of errors), if safety measures are ignored. So failures due to the lack of pre-conversions checks is not a hypothetic scenario, especially failure on the state of rolling our Oracle RPMs, when the system in "transitional state" and can't be safely rebooted. It is an important safety measure if you convert multiple CentOS or RHEL servers to Oracle Linux and need to convert  important production servers. Man page at centos2ol_wrapper. See  Converting CentOS to Oracle Linux with centos2ol script for details

 
**Dec 21, 2020** *dir2tar* -- compresses the directory replacing all files in it with the archive and creating manifest (essentially the list of tarball content). Uses pbzip2 for compression by default. Useful if resulting archive is over 100GB as it checks for interruptions in archiving and many other abnormal situations. It also recognized already archived directories.   Can work in tandem with the  **dormant_user_stats**. Compression program used can be changed via option -a, for example -a pigz . For obvious reasons for large archives only parallel versions of compression programs are acceptable. Tested on tarballs up to 20TB. 

**Nov 23, 2020**  *fspace_mon* --Intelligent monitoring of filesystems free scave via cron and emails.  "Primitive", one level free space monitoring program can be written in an hour or so, but intelligent monitoring of free space with the suppression of redundant messages and flexibility of to who for particular filesystem you need to send emails and what action you need to take is the last critical threshold is breached, is difficult without using some kind of correlation engine. This utility tries to imitate correlation engine and provides three level of alerts (Warning, Serious, and Critical/Fatal) for free space with the ability to specify a mail list (undividual for each monitored filesystem) and an action for the last level (also for each monitored filesystem; action can be a shutdown of the server, cleaning some folder,  or blocking of user logins). Emails warning about insufficient disk space sent to the most recent users, or specified mail list.  Blocks "spam" emails and sends exactly one email after crossing each threshold. Allow to specify fractions of percentage for the last (critical) threshold, for example 99.99%. 

**Nov 23, 2020**  *think* -- this is "Think it over first" (TIOT) type of utility. Very useful for working with remote or critical production server, where a mistake or accidental typo can cost a lot pain/money. Originally was used for preventing accidental reboots, but later made more universal. It allows to create a set of aliases, sourcing which will prevent execution of the command if it is submitted in interactive session printing inread the context in which particular command will be executed (customizable via configuration file.) 

Operated via concept of dangerous options, set of which can be specified for each command to alert sysadmin about possible tragic consequences' or a rush. impulsive  run of such a command, typical when sysadmin is stressed and/or is working under tremendous pressure.  In such circumstances it is important not to make the situation worse.

If option LS is specified in config file for this utility and dangerous options are detected the command tried to convent the command into an ls command and execute it to give you better understanding about which file are affected. Sysadmins know that this is one of the best way to prevent SNAFU with find -exec (or find -delete, or chmod -LR something) but seldom follow this recommendation.

So if you type the command reboot the utility will print the HOSTNAME of the server you are on,  and will ask you to resubmit the command.  while for a command like find  it provides PWD  whe list of "dangerous options" used, if any.  Useful when working on remote server, which in case you do something nasty might require you to buy an airline ticket and fly to the destination instead of TCP packets.  

**Nov 23, 2020**  *soft_reboot*  -- reboots the server only after a given period since the last reboot( by default 90 days) expires, selecting a moment when the server does not run any jobs, as shown by uptime.  Useful for computational cluster nodes, especially if some applications suffer from memory leaks. 

**Nov 23, 2020**  *dir_favorites.pl*  Help to create a usable history of directory favorites. It requires the usage of custom prompt function (provided in  dir_favorites_shell_functions.sh.)   

Favorites are stored in stored in stack accessible by dirs command and consist of two parts -- static (loaded from a file  $HOME/.config/dir_favorites.$HOSTNAME ) and dynamic (created from history). The utility creates a history of accessed directories and a set of aliases such as cd--, 3rb for root/bin,  2esn for /etc/sysconfig/network-scripts. You got the idea. 

If it is invoked with option -m also changes directory favories in MC (Midnight commander) providing dynamic updates. In this case mc hotlist consist of two parts -- static and dynamic. See HTML page for infomation. 


**Nov 05, 2020**  *dirhist* utility was posted. Provides the history of changes in one or several directories.

Designed to run from cron. Uses different, simpler approach than the etckeeper (and does not have the connected with the usage of GIT problem with incorrect assignment of file attributes when reconverting system files). 

If it detects changed file it creates a new tar file for each analysedf directory, for example  **/etc**, **/root**, and **/boot**.  Detects changes in all "critical" files diffs them with previous version, and produces report on  each invocation about changes detected.

All information by default in stored in **/var/Dirhist_base**. Directories to watch and files that are considered important are configurable via two config files **dirhist_ignore.lst** and **dirhist_watch.lst** which by default are located at the root of **/var/Dirhist_base**  tree (as **/var/Dirhist_base/dirhist_ignore.lst** and
**/var/Dirhist_base/dirhist_watch.lst** )

You can specify any number of watched directories and within each directory any number of watched files and subdirectories. The format used is similar to YAML dictionaries, or Windows 3 ini files. If any of "watched" files or directories changes, the utility can email you the report to selected email addresses, to alert about those changes. Useful when several sysadmin manage the same server. Can also be used for checking, if changes made were documented in GIT or other version management system (this process can be automated using the utility admpolice.)

**Nov 2, 2020** *usersync* utility was posted. It syncronizes (one way) users and groups within given interval of UID (min and max)  with the directory or selected remote server (in the latter case files should be assessable via ssh.) ) Useful for provisioning multiple servers that use traditional authentication, and not  LDAP and for synchronizing user accounts between multiple versions on Linux .  Also can be used for "normalizing" servers after acquisition of another company, changing on the fly UID and GID on multiple servers, etc.  Can also be used for provisioning computational nodes on small and medium HPC clusters that use traditional authentication instead of DHCP.  

**Oct 30, 2020** *msync* utility was posted. This is a rsync wrapper that allow using multiple connections for transferring compressed archives or sets of them orginized in the tree (which are assumed iether consist of a single files to a subdirectory with the archive split into chunks of a certain size, for example 5TB ) . Files are sorted into N piles, where N is specified as parameter,  and each pile transmitted vi own TCP connection. useful for transmitted over WAN lines with high latency. I achieved on WAN links with 100Ms latency results comparable with Aspera using 8 channels of transmission. 

**Oct 26, 2020** *emergency_shutdown* utility was posted. The utility works with DRAC (passwordless login needs to be configured) and shutdown the server in N days if it detects a failed disk. Useful for RAID5 without spare drive, or other RAID configurations with limited redundancy.  

**Oct 19, 2020** *dormant_user_stats* utility was posted. The utility lists all users who were inactive for the specified number of days (default is 365). Calculates I-nodes usage too. Use dormant_user_stats -h for more information 

## For more information see:

* http://softpanorama.org/Admin/Sp_admin_utils/index.shtml
