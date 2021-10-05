#!/bin/bash

## NOTE:  You must create a profile called shared under ~/.aws
# --r = AWS Region
#      [default: us-east-1]
#
# --i = L0 instance type
#      [default: r5b.metal]
#
# --e = environment your dependencies live in
#
# --k = key pair
#
# --v = vsphere version.  one of 6.7, 7.0 or 6.5 (use 6.7 unless you really know what you're doing.  the others require considerable tuning to function properly.)
#
# --a = ami id (00b40897c2db81504c = us-east-1 / 043d0b5f17b70f4a3 = us-east-1)
#
# --t = environment type
#    (default: CLASS)
#    (optional: FAT)
#
# --b = id for bring your own volume
#
# --q = profile (only use if you want to use an aws cli profile)
#      [default: default profile]
#
# --x = insert routes for vlans 20-80 pointing at your ENI.  default is yes.  You would only say no to this for troubleshooting.
#
# ./push-centos8-libvirt-with-import.sh --r us-east-1 --k l0-testing --i r5b.metal --e ENV-MUHSOHA-30 --v 6.7 --t FAT --a ami-0b6d7465d3e23bc46

S3BUCKET="centralsa-labs"
S3PREFIX="vmware"
RANDIP=$(echo $RANDOM % 10 + 48 | bc)

r=${r:-us-east-1}
i=${i:-r5b.metal}
e=${e:-NOENV}
v=${v:-6.7}
k=${k:-centralsa-labs-keypair}
a=${a:-ami-0b6d7465d3e23bc46}
t=${t:-FAT}
b=${b:-none}
x=${x:-yes}

while [[ $# -gt 0 ]]; do

     if [[ $1 == *"--"* ]]; then
          param="${1/--/}"
          declare ${param}="$2"
     fi

     shift
done

echo "t= $t"
echo "a= $a"
echo "b= $b"

if [[ "$t" == "CLASS" ]]; then
     ESXHOSTCOUNT=18
     MEM=12
     CORE=3
     MGMTMEM=24
     MGMTCORE=8
else
     ESXHOSTCOUNT=10
     MEM=48
     CORE=8
     MGMTMEM=64
     MGMTCORE=8
fi

version=$(sed "s/\.//g" <<<$v)

cuti=$(echo $i | cut -d'.' -f 2 | tr [:lower:] [:upper:])
cuti=${cuti:0:1}
series=$(echo $i | cut -d'.' -f 1 | tr [:lower:] [:upper:])

RANDNAME=$(openssl rand -hex 1 | tr [:lower:] [:upper:])

if [[ "$b" == "none" ]]; then
     JSON=$(cat centos8params-secure.cf.json | sed "s/INSERTROUTESPLACEHOLDER/$x/g; s/INSTANCETYPEPLACEHOLDER/$i/g; s/ENVSTACKPLACEHOLDER/$e/g; s/KEYPLACEHOLDER/$k/g; s/AMIPLACEHOLDER/$a/g; s/VERSIONPLACEHOLDER/$v/g; s/ENVTYPEPLACEHOLDER/$t/g; s/MGMTCOREPLACEHOLDER/$MGMTCORE/g; s/MGMTMEMPLACEHOLDER/$MGMTMEM/g; s/COREPLACEHOLDER/$CORE/g; s/MEMPLACEHOLDER/$MEM/g; s/ESXHOSTCOUNTPLACEHOLDER/$ESXHOSTCOUNT/g;")
else
     JSON=$(cat centos8paramswithvolume-secure.cf.json | sed "s/INSERTROUTESPLACEHOLDER/$x/g; s/INSTANCETYPEPLACEHOLDER/$i/g; s/ENVSTACKPLACEHOLDER/$e/g; s/KEYPLACEHOLDER/$k/g; s/AMIPLACEHOLDER/$a/g; s/VERSIONPLACEHOLDER/$v/g; s/ENVTYPEPLACEHOLDER/$t/g; s/MGMTCOREPLACEHOLDER/$MGMTCORE/g; s/MGMTMEMPLACEHOLDER/$MGMTMEM/g; s/COREPLACEHOLDER/$CORE/g; s/MEMPLACEHOLDER/$MEM/g; s/ESXHOSTCOUNTPLACEHOLDER/$ESXHOSTCOUNT/g; s/VOLUMEIDPLACEHOLDER/$b/g;")
fi

aws cloudformation create-stack --capabilities "CAPABILITY_NAMED_IAM" "CAPABILITY_IAM" --stack-name "$e-L0-$series$cuti-$RANDNAME" --cli-input-json "$JSON" --region ${r} --template-url https://s3.amazonaws.com/$S3BUCKET/$S3PREFIX/cloudformation/centos-8-libvirt-with-import.yaml
