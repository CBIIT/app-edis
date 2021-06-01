#!/bin/bash

usage() { echo "Usage: $0 [-a <account>] [-t <tier>] [-h]" 1>&2; exit 1; }

account="107424568411"
tier="dev"
load_dir="../load-nedorg-data"

while getopts ha:t: opt
do
    case "${opt}" in
        h) usage
          ;;
        a) account=${OPTARG}
          ;;
        t) tier=${OPTARG}
          ;;
        *) usage
          ;;
    esac
done

cur_dir=$(pwd)
cd $load_dir
ddb_table="nedorgs-${tier}"

npm install
node index.js ${ddb_table}

#load extusers-${tier} table
node batchload.js extusers-${tier} "../docs/NIH External Accounts - No Roles.json"
