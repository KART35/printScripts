#!/bin/bash

# spool.sh by KART35
# 2014

if [[ "$1" == "" ]] # print usage info and exit if no args are given.
then
        printf "Directory in printOutput must be given\n"
        printf "Available dirs:\n"
        ls printOutput | sort
        exit
fi
if [ ! -d "printOutput/$1" ]; then # double check for valid input
        printf "$1 does not exist.\n"
        exit
fi
# get a list of all files, and sort them.
files=$(find printOutput/$1 -maxdepth 2 -type f | sort )
# count the number of files that need to be printed.
fileCnt=$(echo $files | wc -w)
arr=($files) # string to array conversion
# send each of those sorted files to the print queue.
for((cnt=0; $cnt != $fileCnt; cnt++))
do
        # echo ${arr[$cnt]} # some debug info
        lpr -o sides=two-sided-long-edge ${arr[$cnt]}
done
