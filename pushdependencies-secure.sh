#!/bin/bash

# arguments (all are optional):
#
# --r = AWS Region
#      [default: us-east-1]
#
# --t = Timezone
#      [default: Eastern]
#
# --c = Comment
#      [default: nocomment]
#
# --i = Instance type for bastion host
#      [default: t3a.large]
#
# --k = keypair
#
# --b = s3 bucket
#
# --p = s3 prefix
#
# --n = name/alias of whose environment this is
#
# --o = output - either suppress or allow
#      [default: suppress]
#
# --q = profile (only use if you want to use an aws cli profile)
#      [default: default profile]
#
# ./pushdependencies.sh --r us-east-1 --c comment --i t3a.2xlarge --t Central --k centralsa-labs-keypair --b centralsa-labs --p vmware --n SEAHOW --o allow

S3BUCKET="centralsa-labs"
S3PREFIX="vmware"

# Set your defaults here

r=${r:-us-east-1}
t=${t:-Eastern}
c=${c:-nocomment}
i=${i:-t3a.2xlarge}
k=${k:-centralsa-labs-keypair}
b=${b:-centralsa-labs}
p=${p:-vmware}
n=${n:-NOBODY}
o=${o:-suppress}

while [ $# -gt 0 ]; do

     if [[ $1 == *"--"* ]]; then
          param="${1/--/}"
          declare $param="$2"
     fi

     shift
done

RANDNAME=$(openssl rand -hex 1 | tr [:lower:] [:upper:])
JSON=$(cat dependenciesparams-secure.cf.json | sed "s/NAMESALTPLACEHOLDER/$RANDNAME/g; s/S3BUCKETPLACEHOLDER/$b/g; s/KEYPAIRPLACEHOLDER/$k/g; s/S3PATHPLACEHOLDER/$p/g; s/INSTANCETYPEPLACEHOLDER/$i/g; s/INSTANCETYPEPLACEHOLDER/$t/g; s/TIMEZONEPLACEHOLDER/$t/g")

if [[ $o == "suppress" ]]; then
     aws cloudformation create-stack --capabilities "CAPABILITY_NAMED_IAM" "CAPABILITY_IAM" --tags Key="comment",Value="$c" --stack-name "ENV-$n-$RANDNAME" --cli-input-json "$JSON" --region $r --template-url https://s3.amazonaws.com/$S3BUCKET/$S3PREFIX/cloudformation/dependencies.yaml
     echo "ENV-$n-$RANDNAME"
else
     aws cloudformation create-stack --capabilities "CAPABILITY_NAMED_IAM" "CAPABILITY_IAM" --tags Key="comment",Value="$c" --stack-name "ENV-$n-$RANDNAME" --cli-input-json "$JSON" --region $r --template-url https://s3.amazonaws.com/$S3BUCKET/$S3PREFIX/cloudformation/dependencies.yaml
fi
