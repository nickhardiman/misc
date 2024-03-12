#!/bin/bash
# short options and getopts
# https://www.redhat.com/sysadmin/arguments-options-bash-scripts

#---------#---------#---------#---------#---------
# functions

usage () {
   echo "
Syntax: $0 [options] [positional arguments]
options:
zero or more of these
    -h            print this help and exit
    -o thing      thing
    -a thing      another thing
    -y thing      yet another thing
positional arguments:
zero or more of these
    a-positional-argument 
    another-positional-argument
"
}

#---------#---------#---------#---------#---------
echo all arguments
echo \$@ $@

#---------#---------#---------#---------#---------
echo 
echo options

echo display option errors? 0 no, 1 yes
echo OPTERR $OPTERR
echo option values
while getopts "ho:a:y:" OPTION_NAME; do
# while loop continues until getopts returns an error (a non-zero number)
   case $OPTION_NAME in
      h) # display help
         usage
         exit
         ;;
      o) # display thing
         echo OPTARG $OPTARG
         ;;
      a) # display thing
         echo OPTARG $OPTARG
         ;;
      y) # display thing
         echo OPTARG $OPTARG
         ;;
      \?) # If an invalid option is seen, getopts places ? into name
         echo "Error: Invalid option"
         exit
         ;;
   esac
done

# how many things did getopts count?
# eg. -a asdf -o qwer zxcv
#      1   2   3   4   5
echo
echo what is the index of the first non-option argument?
echo OPTIND $OPTIND
echo removing the option arguments
shift $((OPTIND-1))
echo all remaining arguments
echo \$@ $@

#---------#---------#---------#---------#---------
echo
echo positional arguments

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
      echo $1
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
done

echo new array \${POSITIONAL_ARGS[@]}
echo ${POSITIONAL_ARGS[@]}
