#!/bin/bash

usage() { echo "Usage: $0 [-t <tier>] [-p profile] [-h]" 1>&2; exit 1; }

tier="dev"
profile=""

while getopts ht:p: opt
do
    case "${opt}" in
        h) usage
          ;;
        t) tier=${OPTARG}
          ;;
        p) profile=${OPTARG}
          ;;
        *) usage
          ;;
    esac
done

cur_dir=$(pwd)
cd ../load-nedorg-data

npm install
#ddb_table="nedorgs-${tier}"
#node index.js ${ddb_table}

#load extusers-${tier} table
node batchdelete.js extusers-${tier} ${profile}
cd $cur_dir
