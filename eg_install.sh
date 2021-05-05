#!/bin/bash
#: eg_install.sh: install eg and populate custom and example directories from tldr files and original eg files correspondingly
#: Copyright Nikolai Bezroukov, 2021. Perl Artistic License.
#:
#: Invocation:
#:     eg_install.sh  
#
# ====================================================================================
# 1.0 bezroun 2021/05/02  Initial implementation
# 1.1 bezroun 2021/05/04  Diagnistics improved. Logging of steps added
#======================================================================================
VERSION='1.1'
step_no=1

function sanity_chk
{
   if [[ $1 == 'd' ]] && [[ ! -d $2 ]]; then 
      echo "[FAILURE] $3";  exit $4; 
   elif [[ $1 == 'f' ]] && [[ ! -f $2 ]]; then
      echo "[FAILURE] $3";  exit $4; 
   fi   
}
function success
{
   printf "[OK] Step $step_no: $current_step\n==========================================================================================\n";
   sleep 3
}
function step
{
   printf "\nStep $step_no: $1\n"   
   current_step=$1
   (( step_no++ ))
}

printf "\nEg_installer Version $VERSION " `date +"%y/%m/%d %H:M:"`
echo
cd
if [[ -f ~/eg-master.zip && -f ~/tldr-main.zip ]]; then
   echo "Both required zip files eg-master.zip and tldr-main.zip are present. We can proceed with the installation"
else
   echo "The script requires that files eg-master.zip and tldr-main.zip to be present in your home directory. Exiting..." 
   exit 255
fi 

step "Unziping ~/eg-master.zip and moving ~/eg-master/eg it to ~/bin/eg"
mkdir -p ~/.eg/Ex0 # create both .eg and .eg/Ex0
sanity_chk d ~/.eg/Ex0 "Failed to create ~/.eg/Ex0" 1
unzip ~/eg-master.zip
[[ ! -d ~/bin ]] && mkdir ~/bin
mv ~/eg-master/eg ~/bin/eg; 
sanity_chk d ~/bin/eg "Failed to move ~/eg-master/eg to ~/bin" 1
mv ~/eg-master/eg_exec.py ~/bin
success

step "Creating .egrc file"
cat > ~/.egrc <<EOF
[eg-config]
examples-dir = ~/.eg/Ex1
custom-dir = ~/.eg/Ex0
EOF
sanity_chk f ~/.egrc "Failed to create ~/.egrc" 2
success

step "Move examples from eg and tldr to directories specified in .egrc"
mv ~/bin/eg/examples ~/.eg/Ex1; sanity_chk d ~/.eg/Ex1 "Failed to move ~/bin/eg/examples ~/.eg/Ex1" 3  
unzip ~/tldr-main.zip
mv ~/tldr-main/pages ~/.eg/Ex0; sanity_chk d ~/.eg/Ex0 "Failed to move ~/tldr-main/pages ~/.eg/Ex0" 3 
success

step "[Optional] Create aliases for the command"
alias eg='~/bin/eg_exec.py' >> ~/.bash_profile     # alias for running the command
alias eeg='~/bin/eg_exec.py -e' >> ~/.bash_profile # alias for editing custom examples
success

echo "Test if the installation was successful. if necessary modules are missing install them"
~/bin/eg_exec.py ls

rm -r ~/tldr-main ~/eg-master
echo
echo "End of eg_install.sh run" `date +"%Y/%m/%d %H:M:"`

