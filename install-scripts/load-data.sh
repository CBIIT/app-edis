#!/bin/bash

usage() { echo "Usage: $0 [-t <tier>] [-p profile] [-f file] [-h]" 1>&2; exit 1; }

tier="dev"
profile=""
filename=""

while getopts ht:p: opt
do
    case "${opt}" in
        h) usage
          ;;
        t) tier=${OPTARG}
          ;;
        p) profile=${OPTARG}
          ;;
        f) filename=${OPTARG}
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
#filename="../docs/NIH External Accounts - No Roles - Address.json"

#load extusers-${tier} table
node batchload.js extusers-${tier} "${filename}" ${profile}
cd $cur_dir
