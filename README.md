# Preannoncement of admutils -- softpanorama collection of potentially useful utilities

Currently we plan to include the follwoign (this plan subject to change without notice):

1. etcdiff -- Creates tar file and  displays files changes since previous invocations and differences. Can be used as a stage to GIT or for the control of actions of multiple sysadmins with the utlity etcpolice.
1. dormant_user_stats -- list users who were inactiove for the specified number of days (defualt is 365). Calculates i-nodes usage too. 
1. xrsync -- rsync using multiple connections. Files are sorted into piles and  each pile tranmitted vi own TCP connection.
useful for tranmitted over WAN lines with high latency
1. usersync -- sync users and groups above centrain uid and gid threaholds with the selected remove server (files should be assesible via ssh)
if not /tmp/name_of_remote server directory should contain them 
1. mkuser -- create the same user on multiple servers
1. dir2tar -- compress the directory replace all files in it creating manifest and md5 checksum. Uses pbzip2 archiver by default. 
1. reboot_manager -- reboots server once a month or quarter (perios if selectable) if the server is inacive as shown by uptime
1. emerergency_shutdown -- Currently works with Dell Drac only, whichshould be configured for passwordless ssh login from the server that runs this utility.  Detects that a disk    in RIAD 5 array failed it shut down the server.
1. heartbeatmon -- monitoring multiple servers via heatbeat on common NFS or GPFS filesystem 
1. fspace_mon -- provides three level of alerts for free speace with the ability to specify an action on the last level (for example shutdown of the server or block of user logins) 
1. intelliping -- ping all servers from the list containing thie DRAC/Lo addresses and main interface IP (pinging separatly Drac/ILO and main interface) and informs if power was restored, or the server rebooted woth DRAC/ILO on byt main interface is not availbe or vise versa 
1. useractivity -- collects statistics of user logins and try to detect the user pattern of usage of the server. If runs oon multiple servers information will be merged. 
1. inform_recent_users -- allow sending message only to users who login to the server for the given period
1. sgc -- sign git change -- add name of sysadmin to the git record even if he works as root. 
1. rootpolice -- verifies that changes in  /etc are all documented in git. 
