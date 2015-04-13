#!/bin/bash
myFile="/home/jmontibello/notify/notifyhash.txt"
myLog="/iiidb/errlog/usererr"
#check that the usererr file is there.
if [ ! -f "$myLog" ]; then
    myLog="/iiidb/errlog/usererr.formatted"
    if [ ! -f "$myLog" ]; then 
	myLog="/iiidb/errlog/usererr.work"
	if [ ! -f "$myLog" ]; then
	    echo "Error: No usererr file found."
	fi
    fi
fi

## function sendchanges
#
sendchanges()
{
	echo "$myHash" > $myFile
	echo "Users who tried to log in:"
	#This is the meat of the script.
        #dump the whole file with cat
	#use grep to look for a phrase that signifies a particular error:
	#a patron trying to login whose dartID doesn't match anything
	#in Sierra. For each line that has that signifier, parse out the 
	#dartID value and append it to a url string.
	#Each failed login creates about 5 lines in the error log, so we
	#sort them and then dedupe the list.
        myList=`cat $myLog | grep "no library patron with" | awk -F"no library patron with: " '{ print "http://lookupdnd.dartmouth.edu/full?lookup=" $2 "\n" }' | sort | uniq`
	echo "$myList"
	echo "Other messages:"
	echo `grep -v "no library patron with" $myLog `
}
#check that the hash of the previous file is there.
if [ -f "$myFile" ]; then
    while read line
    do
    myHash=`/usr/bin/md5sum $myLog | /bin/awk -F" " '{ print $1 }'`
    #check if the old hash is the same as the new.
    #if it is, we know the file hasn't changed and 
    #we assume that it was sent out last time so we 
    #just send a message saying nothing has happened.
    if [[ $myHash = $line ]]; then
	echo "System messages file on Sierra has *not* changed."
	echo "$myHash" > $myFile
    #if the file happens to be empty, there's nothing we can do
    #except report it out.
    elif [[ $myHash = '' ]]; then
	echo "myhash is empty"
    #if it's not empty and it's not the same, we want 
    #to generate a report of the changed file.
    else 
        echo "System messages file on Sierra has changed."
        #echo $myHash
	sendchanges;
	exit;
    fi
    done < $myFile
else
    echo "notifyhash.txt not found."
    #echo $myHash
    `touch $myFile`
    sendchanges
fi




