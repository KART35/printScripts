#!/bin/bash

# print.sh by KART35
# 2014

outfile=output.txt
date +"%A, %B %d, %y %T" > ./${outfile}
printf "\n" >> ${outfile}

#initialize some stats counters.
let "errCnt=0"
let "updateCnt=0"
let "thisErr=0"

wd=$(pwd)
hPos=$(tput cols)
for path in ./*; do
        [ -d "${path}" ] || continue # if not a directory, skip
        dname="$(basename "${path}")"
        for ph in $dname/*; do # for each directory (could be a project):
                [ -d "${ph}" ] || continue # if not a directory, skip
                if [[ ":${ph}:" ==  *"printOutput"* ]] # don't process the output dir.
                then
                        continue
                fi
                dirname="$(basename "${ph}")"
                printf "running 'make run' on ${ph}\t"
                if [[ "$1" == "clean" ]]; then
                        make -C ${ph} clean > /dev/null # run 'make clean' on all projects if the firsr arg is 'clean'
                fi
                makeRes=$(make -C ${ph} run 2>&1) # run 'make run' on all projects
                if [[ $makeRes == *error* ]]; then #if we get a compilation error, print the message,
                        ((errCnt++)) # update our stats counters...
                        ((thisErr++))
                        tput cup $hPos $(tput lines)
                        echo "[^[[0;31;40mFAIL^[[0m]" # print '[FAIL]' with red text
                        echo "^[[0;31;40m$makeRes^[[0m" # and hilight the message in red.
                fi
                printf "${ph}\n\n" >> ${outfile} # this section concatinates all of the output.txt files
                cat ${ph}/output.txt >> ${outfile} # from each project into one large one.
                printf "\n========\n" >> ${outfile}
                mkdir -p printOutput/${ph}
                if [ ${ph}/output.txt -nt printOutput/${ph}/0-main.c.pdf ]; then # do we regen all those PDFs?
                        for file in ${ph}/*.c; do #for each C file in the project, do the following:
                                srcHeader="// Project: ${file}\n// (month.day/project/file)\n" # make an informational header.
                                printf "$srcHeader\n\n" | cat - $wd/${file} | expand -t 7 | pygmentize -l c | aha > source-color.html # colorize, and format in HTML.
                                if [ "$(echo ${file} | grep main.c)" != "" ]
                                        then
                                        outName=$(echo ${file} | sed "s/\//\/0-/2") # Give main.c the highest sort priority.
                                        else                                                                      # All other C files are given the second
                                        outName=$(echo ${file} | sed "s/\//\/1-/2") # highest priority and aresorted alphabetically.
                                fi
                                xvfb-run -a wkhtmltopdf -s letter source-color.html printOutput/$outName.pdf #pdf conversion
                        done
                        if [[ "$(ls ${ph}/*.h 2>/dev/null)" != "" ]]; then # for all headers in the project:
                                for file in ${ph}/*.h; do
                                        srcHeader="// Project: ${file}\n// (month.day/project/file)\n" # make an informational header.
                                        printf "$srcHeader\n\n" | cat - $wd/${file} | expand -t 7 | pygmentize -l c | aha > source-color.html # colorize, and format in HTML.
                                        outName=$(echo ${file} | sed "s/\//\/2-/2") # give all headers the third highest sort priority.
                                        echo printOutput/$outName.pdf
                                        xvfb-run -a wkhtmltopdf -s letter source-color.html printOutput/$outName.pdf #pdf conversion
                                done
                        else
                                echo "no headers in ${ph}"
                        fi
                        if [[ "$(ls ${ph}/*.txt 2>/dev/null)" != "" ]]; then # for all text files in the project:
                                for file in ${ph}/*.txt; do
                                        srcHeader="Output for $(echo ${ph}/build/*.o)" # print an informational header

                                        outName=$(echo ${file} | sed "s/\//\/3-/2") # give output files the lowest sort priority.
                                        printf "$srcHeader\n\n" | cat - $wd/${file} > printOutput/$outName
                                done
                        else
                                echo "no text files in ${ph}"
                        fi
                        ((updateCnt++)) # incriment the stats counter
                fi
                if [ $thisErr == 0 ]; then # got to here with no errors? good. print an '[OK]' in green.
                        tput cup $hPos $(tput lines)
                        echo "[^[[0;32;40mOK^[[0m]"
                fi
                let "thisErr=0" # errors are per project, so reset this here...
        done
done
# cleanup and print general stats
rm -f source-color.html
