#!/bin/bash
#Removes traffic spikes in RRD files which are caused by reboots or counter roll-overs.
#Written by Dennis Hagens - root@ipaddr.nl

#Argument checking

if [[ $1 = "-h" ]]
then
  echo "Usage: $0 FILE MAXIMUM_VALUE"
  echo "MAXIMUM_VALUE describes the maximum bandwidth of the interface of this RRD"
  echo "This value for example can be: 100000000 which is equivelent to 100Mbit/s"
  exit
fi

if [[ -z "$1" ]] || [[ -z "$2" ]]
then
  echo "This script requires 2 arguments. See $0 -h"
  exit 1
fi

if [[ ! -f $1 ]]
then
  echo "Argument 1 is not a valid or existing file. See $0 -h"
  exit 1
fi

re='^[0-9]+$'
if ! [[ $2 =~ $re ]]
then
  echo "Argument 2 is not a valid integer. See $0 -h"
  exit 1
fi


#Actually doing shit

echo "Working on file: $1"

if [[ -f $1.backup ]]
then
  echo "There already is a backup file... not sure what to do. Delete it manually if you feel confident about it."
  exit 1
fi

echo "Creating backup to $1.backup"
cp $1 $1.backup

echo "Adjusting max values"
for i in `rrdtool info $1 | grep "^ds" | cut -d'[' -f 2 | cut -d']' -f 1 | sort | uniq`
do
  rrdtool tune $1 -a $i:$2
done

echo "Creating XML file"
rrdtool dump $1 > $1.xml

echo "Moving $1 to $1.old"
mv $1 $1.old

echo "Restoring from XML file"
rrdtool restore $1.xml $1 -r

echo "Things should be good now."

exit
