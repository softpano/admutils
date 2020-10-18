# Preannoncement of admutils -- softpanorama collection of potentially useful utilities

Currently we plan to include the follwoign (plan subject to change without notice):

1. etcdiff -- Creates tar file and  displays files changes since previous invocations and differences. Can be used as a stage to GIT or for control of actions os multiple sysadmins
1. dormant_user_stats -- list users who were unactiove for the specified number of days (defulat 365)
1. multirsync -- rsync using multiple connections. Files are sorted into piles and  each pile tranmitted with thier own chqnnel.
              useful for tranmitted over WAN lines with high latency
1. usersync -- sync users and groups above centran threahold with remove server
1. mkuser -- create the same user on mltiple servers
1. dir2tar -- compess the directory replace all files in ti with the pbzip2 archive
1. reboot_manager -- reboots server once a month or quater if it depeted that the serve is inacive. 
1. emerergency_shutdown -- Currently works with Dell Drac only. Detects that a disk in RIAD 5 array failed it shut down the server.
1. heatbeatmon -- monitoring multiple servers via heatbeat on common NFS or GPFS filesystem 
1. fspace_mon -- provides three level of alerts for free speace and the ability to specify an action on the last level (sfor example shutdown of the server or block of user logins) 
1. intelliping -- ping all servers from the list (pinging seperatly Drac/ILO and main interface) and informs if power war restored or server rebooted or power is up but the server is down 
1. useractivity -- collects last statistics and try to detect the user pattern of usage of the server. If runs oon multiple servers information will be merged. 
1. inform_recent_users -- allow sending message only to users who login to the server for given period
1. sc -- sign change -- add name of sysadmin to the git record even if he works as root.  
