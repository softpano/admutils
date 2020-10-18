# Preannouncement of admutils
# Softpanorama collection of potentially useful sysadmin utilities

Currently we plan to include the following written by me over the years utilities (this plan subject to change without notice). this page is not maintained often as I prefer HTML to Markup. 

See html version of this page https://github.com/softpano/admutils/readme.shtml for more recent and complete information

## List of utilities 

1. *dormant_user_stats* -- list users who were inactive for the specified number of days (default is 365). Calculates I-nodes usage too. 
1. *etcdiff* -- Creates tar file and  displays files changes since previous invocations and differences. Can be used as a stage to GIT or for the control of actions of multiple sysadmins with the utility etcpolice.
1. *xrsync* -- rsync using multiple connections. Files are sorted into piles and  each pile transmitted vi own TCP connection.
useful for transmitted over WAN lines with high latency
1. *usersync* -- sync users and groups above certain UID and GID thresholds with the selected remove server (files should be assessable via ssh)
if not /tmp/name_of_remote server directory should contain them 
1. *mkuser* -- create the same user on multiple servers. Written for small HPC clusters. 
1. *dir2tar* -- compresses the directory replacing all files in it with the archive and creating manifest and md5 checksum. 
Uses pbzip2 archiver by default. 
1. *reboot_manager* -- reboots server once a month or quarter (period if selectable) if the server is inactive as shown by uptime
1. *emerergency_shutdown* -- Currently works with Dell DRAC only, which should be configured for passwordless ssh login from the server that runs this utility.  Detects that a disk    in RAID 5 array failed it shut down the server.
1. *heartbeatmon* -- monitoring multiple servers via heartbeat on common NFS or GPFS filesystem 
1. *fspace_mon* -- provides three level of alerts for free space with the ability to specify an action on the last level (for example shutdown of the server or block of user logins) 
1. *intelliping* -- ping all servers from the list containing both DRAC/ILO addresses and main interface IP 
(pinging separately DRAC/ILO and main interface) and informs if power was restored, or the server rebooted with DRAC/ILO 
on but main interface is not available or vise versa 
1. *inform_recent_users* -- allow sending message only to users who login to the server for the given period
1. *sgc* -- sign git change -- add name of sysadmin to the git record even if he works as root. 
1. *rootpolice* -- verifies that all changes in  /etc are all documented in git. Useful if mutile sysadmin exists for the server. 
1. *useractivity* -- collects statistics including IPs of user logins from /var/log/wtmp and tries to detect the user pattern of usage 
login to the server. If runs on multiple servers information will be merged.  

**HISTORY**

[Oct 19, 2020] *dormant_user_stats* utility was posted. The utility lists all users who were inactive for the specified number of days (default is 365). Calculates I-nodes usage too. Use dormant_user_stats -h for more information 

See 
* http://softpanorama.org/Admin/index.shtml
* http://softpanorama.org/Admin/Sp_admin_utils/index.shtml
