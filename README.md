# Softpanorama collection of potentially useful sysadmin utilities


This project is about publishing of a set of written by me over the years sysadmin utilities (this plan subject to change without notice).

**NOTE**: This page is not maintained often, as I prefer HTML to Markup. See html version of this page at http://softpanorama.org/Admin/Sp_admin_utils/index.shtml for more recent and complete information.

## History

**Nov 05, 2020**  *dirhist* utility was posted. Provides the jistory of changes in one or several directories was posted on GitHub
Designed to run from cron. Uses different, simpler approach than the etckeeper. Does not use GIT or any other version control system as they proved to be of limited use for sysadmin, unless there are multiple sysadmins on the server. Creates a daily new tar file for selected set of directories, for example  /etc /root, and /boot  Detects all "critical" changed file, diffs them with previous version, and produces report.

All information by default in stored in **/var/Dirhist_base**. Directories to watch and files that are considered important are configurable via two config files **dirhist_ignore.lst** and **dirhist_watch.lst** which by default are located at the root of **/var/Dirhist_base**  tree (as **/var/Dirhist_base/dirhist_ignore.lst** and
**/var/Dirhist_base/dirhist_watch.lst** )

You can specify any number of watched directories and within each directory any number of watched files and subdirectories. The format used is similar to YAML dictionaries, or Windows 3 ini files. If any of "watched" files or directories changes, the utility can email you the report to selected email addresses, to alert about those changes. Useful when several sysadmin manage the same server. Can also be used for checking, if changes made were documented in GIT or other version management system (this process can be automated using the utility admpolice.)



**Nov 2, 2020** *usersync* utility was posted. It syncronizes (one way) users and groups within given interval of UID (min and max)  with the directory or selected remote server (in the latter case files should be assessable via ssh.) ) Useful for provisioning multiple servers that use traditional authentication, and not  LDAP and for synchronizing user accounts between multiple versions on Linux .  Also can be used for "normalizing" servers after acquisition of another company, changing on the fly UID and GID on multiple servers, etc.  Can also be used for provisioning computational nodes on small and medium HPC clusters that use traditional authentication instead of DHCP.  

**Oct 30, 2020** *msync* utility was posted. This is a rsync wrapper that allow using multiple connections for transferring compressed archives or sets of them orginized in the tree (which are assumed iether consist of a single files to a subdirectory with the archive split into chunks of a certain size, for example 5TB ) . Files are sorted into N piles, where N is specified as parameter,  and each pile transmitted vi own TCP connection. useful for transmitted over WAN lines with high latency. I achieved on WAN links with 100Ms latency results comparable with Aspera using 8 channels of transmission. 

**Oct 26, 2020** *emergency_shutdown* utility was posted. The utility works with DRAC (passwordless login needs to be configured) and shutdown the server in N days if it detects a failed disk. Useful for RAID5 without spare drive, or other RAID configurations with limited redundancy.  

**Oct 19, 2020** *dormant_user_stats* utility was posted. The utility lists all users who were inactive for the specified number of days (default is 365). Calculates I-nodes usage too. Use dormant_user_stats -h for more information 

## For more information see:

* http://softpanorama.org/Admin/Sp_admin_utils/index.shtml
