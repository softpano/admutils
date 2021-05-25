# "Back to basics" -- Softpanorama collection of potentially useful simple sysadmin utilities


<p>This project is about publishing of a small set of sysadmin utilities that might help to administer Unix server in a &quot;classic&quot; 
way: using command line tools, pipes and, if necessary, bash as a glue that connects small scripts (Written in Perl or Python or 
Ruby), or programs (for example written in GOlang) each of which perform some limited, well defined function.&nbsp; This is an 
alternative of adopting yet another complex system with yet another DSL (domain specific language) for each and every problem.&nbsp;  
   
<p>Actually Unix created a new style of computing, a new way of thinking of how to attack complex problems, especially sysadmin 
problems. This style was essentially the first successful component model in programming. And despite its age it still holds it own.&nbsp; 
As Frederick P. Brooks Jr (another computer pioneer who early recognized the importance of pipes) noted, the creators of Unix 
&quot;...attacked the accidental difficulties that result from using individual programs together, by providing integrated libraries, 
unified file formats, and pipes and filters.&quot;<p>By sticking to a single integration language (bash), this approach somewhat differs from the approach 
based on scripting written in the DSL for particular configuration management system, be it Ansible, Puppet or something else. All 
of them reintroduced on a new parallel level ideas of IBM JCL into Unix environment -- waterfall execution of steps required for 
accomplishing given task. Those utilities, of course, can be used as a part of Ansible scripts, when it makes sense. <p>But often using 
bash and pdsh ( or Ansible in &quot;ad hoc&quot; mode, cexec, parallel or other similar tool) with bash is simpler and more straightforward, more modifiable, more easily manageable. 

<p>BTW, 
historically, Unix shell (and IBM REXX) wiped the floor with JCL.&nbsp; So instead of having, say, Ansible as a superstructure with 
its own DSL, you use it as a component (in &quot;as hoc&quot; mode) and bash as our DSL.
   
<p>So instead of having, say, Ansible as a superstructure with 
its own DSL, you use it as a component and&nbsp; bash as our DSL. 

<p>The utilities in question were written by me over the years and most of them have a common framework "compiler style" framework with the special attention on providing meaningful diagnostic messages. To that extent they all rely of a set of components that provide generation of messages somewhat similar in style to the old IBM PL/1 compliers. Verbosity can be regulated via option -v. 
   
<p>Quality, the level of 
maturity and usefulness vary. You can view them as a kind of my personal protest against the overcomplexity of the current sysadmin 
environment. Now there are way too many tools available to make simple tasks complex and complex unsolvable :-)
   
<p>Generally Linux system administration gradually moves to the &quot;Windows-way&quot; of doing things -- to tools that provide GUI and 
&quot;blackboxing&quot; of OS API and internals. Many DevOps toys can be viewed as steps in this particular direction. Some new subsystems 
like systemd also belong to this category. They all have their place but they all add too much complexity and in small companies 
adoption of them entails significant risks due to the lack of people able to master them all. </p>  
   
<p>In this sense you can view this collection as a very small contribution to the &quot;back to basics&quot; movement among sysadmins.</p>

<p>Moreover, for small and medium organization adoption of overly complex tools entrain significant risks. If the organization 
adopted a set of complex tools and a person who known those tool leaves, often the situation deteriorates pretty quickly as there is 
no cost effective way to replace him/her. Lack of documentation is typical and can bite very hard to the level of partial or 
complete paralysis.</p>

<p>Sticking to classic Unix capabilities often is a better approach to system administration then the adoption of a bunch of complex 
shiny tools that no normal person can learn in depth in his life. Drawbacks often cited for &quot;primitive&quot; approaches of managing 
servers (for example with cloning /etc/passwd /etc/group files using ssh instead of Active directory or some other directory) can 
often be compensated quite easity (for example with the automatic synchronization of passwd files on demand via ssh form some 
&quot;etalon&quot; server, see below ; it is also possible decompile and generate useradd command using diff of two passwd/group files). 
Similarly a lot of collection of data for monitoring can be done using NFS3 and does not require SSH or some proprietary protocol. 
And analysis of logs is better performed by custom utilities tuned to your particular situation or at least enhanced third party 
scripts, instead of some complex system. Same is true for backup although here your mileage may vary. Often &quot;bare metal&quot; backup can 
be done via tar or Rsync and does not require complex tools with additional (and probably less secure then ssh) protocols.</p>

<p>At the same time classic Unix provides unmatched flexibility which some modern approaches considerably diminish squeezing 
sysadmin into
<a rel="nofollow" style="box-sizing: border-box; background-color: rgb(255, 255, 255); color: var(--color-text-link); text-decoration: underline; outline-width: 0px; font-family: -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, Helvetica, Arial, sans-serif, &quot;Apple Color Emoji&quot;, &quot;Segoe UI Emoji&quot;; font-size: 16px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: start; text-indent: 0px; text-transform: none; white-space: normal; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px;" href="https://en.wikipedia.org/wiki/Procrustes">
Procrustean bed</a> of badly designed and overly complex solutions.</p>

<p>Initially I published on GitHub three utilities from this set:
<a itemprop="name codeRepository" href="https://github.com/softpano/neatperl">neatperl</a>,
<a href="https://github.com/softpano/neatbash">neatbash</a> and <a href="https://github.com/softpano/saferm">saferm</a> . IMHO 
neatbash fills the &quot;missing link in creation of simple bash IDE, based on Midnight commander and some editor (say, vim). I thought 
that sysadmin will appreciate and it will use it. Unfortunately it was 
by-and-large ignored. And for developers one of main stimulus for further development is the positive feedback loop.&nbsp; As Fred Brooks 
notes in 1975 in his groundbreaking book &quot;The Mythical Man-Month: Essays on Software Engineering&quot; <em>the difference in effort required 
to produce the&nbsp; utility &quot;for yourself&quot; and its publishable form can be ten times or more. </em>This sacrifices in 
time and&nbsp; effort is difficult to commit too if you suspect that this is all&nbsp; &quot;putting program on the shelf&quot; activity -- 
creating programs that nobody will use.&nbsp; My only hope is that&nbsp; &quot;back to basics&quot; movement will strengthen with time.</p>

<p>The trend now is toward &quot;integrated&quot; configuration management solutions like Ansible ( reinvention of IBM JCL on a new level), which 
have <a href="../unix_conf_management.shtml">their own weak spots</a>&nbsp; And it is difficult to fight against fashion in 
software, much like in women cloth.&nbsp; But again, some of the utilities listed below can be used as steps 
in Ansible playbooks you develop. </p>

**NOTE**: This page is not maintained often, as I prefer HTML to Markdown. For extended  version  of this page at http://softpanorama.org/Admin/Sp_admin_utils/index.shtml  It also might contain more recent and complete information.

## History
<p><b>[May 05, 2021] <a href="../../../Dotfiles/Eg_install/eg_install.shtml">eg_install.sh Installation script for eg which allow to 
reuse tldr pages and edit them creating private knowledgebase with examples of major Linux utilities</a></b></p>
<p>It is impossible to remember details of Linux utilities: there are too many of them and some are quite complex (<tt>find</tt>,
   <tt>xargs</tt>, <tt>grep</tt>, <tt>systemctl</tt>, etc). To compensate for the low quality on Linux man pages (which 
typically lack meaningful examples) you can use community database (for example<a rel="noreferrer noopener" target="_blank" title="https://github.com/tldr-pages/tldr" tabindex="-1" href="https://github.com/tldr-pages/tldr"> 
tldr database</a> available from GitHub; it can be viewed using Web browser from
   <a rel="noreferrer noopener" target="_blank" title="https://tldr.ostera.io/find" tabindex="-1" href="https://tldr.ostera.io/find">ostera.io</a>) or to create a private database of examples, partially or fully extracted from 
   <tt>.bash_history</tt>. 
The latter allows to adapt examples to your needs and as such is closer to the idea of a knowledgebase, although one 
does not exclude another.</p>

   <p>I experimented with adaptation for this purpose of
   <a rel="noreferrer noopener" target="_blank" title="https://github.com/srsudar/eg" tabindex="-1" href="https://github.com/srsudar/eg">Python script eg</a>, available from GitHub and got encouraging results. The idea is to supplement the default set of 
pages with examples provided with <tt>eg</tt> with pages from <tt>tldr</tt> and gradually enhance and edit them by 
incorporating own examples from <tt>.bash history</tt>.</p>

   <p>The script <tt>eg</tt> uses two directories for storing the examples files (one for each utility; each written in the 
subset of Markdown)</p>
<ol>

<li><b>custom</b> directory -- the directory in which you can edit files using option <tt>-e</tt> (for example <tt>eg -e find</tt>) 
</li>

<li><b>default</b> directory -- the directory for the small set of examples which comes with the script. </li>
</ol>

   <p>If pages for the particular tool/utility are present in both, <tt>eg</tt> merges them creating composite page. So it 
is possible for example to store your own example in custom directory, and tldr in default directory but I prefer to 
edit tldr pages directly.</p>

   <p>To create a private knowledgebase of examples that uses the suggested above format with set of tldr pages as the 
initial content of the knowledgebase, you need first to download two zip files from GitHub <tt>eg-master.zip</tt> and
<tt>tldr-main.zip</tt> to your home directory. That allows to avoid pains with proxy.</p>

   <p>After that run the following installation script. Alias <tt>eg</tt> needs to be added to your <tt>.bash_profile</tt> 
or to <tt>.bashrc</tt>, depending on how your dot files are organized. The script adds it <tt>.bash_profile</tt> which 
might be incorrect.</p>

   <p>See <a href="../Sp_admin_utils/eg_install.shtml">Admin/Sp_admin_utils/eg_install.shtml</a> and <a href="../Tips/helpers.shtml">Linux command 
   line helpers</a> for more details </p>


**Dec 28, 2020** *centos2ol_wrapper* Wrapper with sanity checks for centos2ol.sh CentOs to Oracle Linux convertion script. It incorporates several "no nonsense" checks that make success of the conversion more probable. I experienced around 30% failure rate iin my tests and 10% (or one server out of ten failed to report after the conversion was finished). Serious troubles include but not limited to  deletion of hundreds of vital RPMs ( due to my mistake made out  of frustration; nit stll no protection from this kind  of errors), if safety measures are ignored. So failures due to the lack of pre-conversions checks is not a hypothetic scenario, especially failure on the state of rolling our Oracle RPMs, when the system in "transitional state" and can't be safely rebooted. It is an important safety measure if you convert multiple CentOS or RHEL servers to Oracle Linux and need to convert  important production servers. Man page at centos2ol_wrapper. 

See http://www.softpanorama.org/Commercial_linuxes/Oracle_linux/conversion_of_centos_to_oracle_linux.shtml for details

 
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

You can specify any number of watched directories and within each directory any number of watched files and subdirectories. The format used is similar to YAML dictionaries, or Windows 3 ini files. If any of "watched" files or directories changes, the utility can email you the report to selected email addresses, to alert about those changes. Useful when several sysadmin manage the same server. Ca n also be used for checking, if changes made were documented in GIT or other version management system (this process can be automated using the utility admpolice.) Can be integrated with GIT for pushing all changes into GIT automatically

**Nov 2, 2020** *usersync* utility was posted. It allows to manage small set of users without any directory or NIS. It synchronizes (one way) users and groups within given interval of UID (min and max)  with the directory or selected (etalon) remote server (files should be accessible via ssh.) Useful for provisioning multiple servers that use traditional authentication, and for synchronizing user accounts between multiple versions on Linux without LDAP or Active Directory.  Also can be used for "normalizing" servers after acquisition of another company, changing on the fly UID and GID on multiple servers, etc.  Can also be used for provisioning computational nodes on small and medium HPC clusters that use traditional authentication without NIS. 

**Oct 30, 2020** *msync* utility was posted. This is a rsync wrapper that allow using multiple connections for transferring compressed archives or sets of them orginized in the tree (which are assumed iether consist of a single files to a subdirectory with the archive split into chunks of a certain size, for example 5TB ) . Files are sorted into N piles, where N is specified as parameter,  and each pile transmitted vi own TCP connection. useful for transmitted over WAN lines with high latency. I achieved on WAN links with 100Ms latency results comparable with Aspera using 8 channels of transmission. 

**Oct 26, 2020** *emergency_shutdown* utility was posted. The utility works with DRAC (passwordless login needs to be configured) and shutdown the server in N days if it detects a failed disk. Useful for RAID5 without spare drive, or other RAID configurations with limited redundancy.  

**Oct 19, 2020** *dormant_user_stats* utility was posted. The utility lists all users who were inactive for the specified number of days (default is 365). Calculates I-nodes usage too. Use dormant_user_stats -h for more information 

## For more information see:

* http://softpanorama.org/Admin/Sp_admin_utils/index.shtml
