#!/bin/bash

# arguments (all are optional):
#
# --n = name/alias of whose environment this is
#      [default: NOBODY]  <-- please dont leave it at this
#
# --p = profile (only use if you want to use an aws cli profile)
#      [default: default profile]
#
# ./push67-secure.sh --p myprofilename --n myfirstname

n=${n:-NOBODY}

while [ $# -gt 0 ]; do

     if [[ $1 == *"--"* ]]; then
          param="${1/--/}"
          declare $param="$2"
     fi

     shift
done

EASTSIDE=$(./pushdependencies-secure.sh --r us-east-1 --c centralsa-labs --i t3a.2xlarge --t Central --b centralsa-labs --p vmware --k centralsa-labs-keypair --n $n)

# sleep standing up apparently. 3600 seconds is one hour

seconds=6000
date1=$(($(date +%s) + $seconds))

while [ "$date1" -ge $(date +%s) ]; do
     date2=$(($(date +%s)))
     date3=$(($date1 - $date2))
     minleft=$(($date3 / 60))
     echo "$minleft minutes left..."
     sleep 60
     clear
done

# Now push the L0s into the dependency environments

./push-centos8-libvirt-with-import-secure.sh --r us-east-1 --i r5b.metal --e $EASTSIDE --v 6.7 --t FAT --a ami-0b6d7465d3e23bc46 --k centralsa-labs-keypair

exit 0
