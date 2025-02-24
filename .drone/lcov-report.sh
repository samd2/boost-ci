#!/bin/bash

set -x
set -e

SKIPLIST=""
RUNCODECOV_FLAGS=""

pwd

export CODECOV_SCRIPT=${BOOST_CI_SRC_FOLDER}/ci/travis/codecov.sh
export CI_DIR=${BOOST_CI_SRC_FOLDER}/ci
export BOOST_CI_CODECOV_IO_UPLOAD=skip"

export EXPORT_BOOST_SRC_DIR="yes"

touch /tmp/failed.txt
touch /tmp/succeeded.txt

# mkdir -p /opt/github/boostorg
# cd /opt/github/boostorg
# git clone -b "develop" --depth 1 "https://github.com/boostorg/boost.git"
# cd boost
cd $BOOST_ROOT
# clone all submodules
git submodule update --init

# Run at least one full build that installs everything
cd libs/accumulators

$CODECOV_SCRIPT
cd ../..

textpart1='#!/bin/bash
set -x
reponame=$1
echo "reponame is $reponame"
skiplist="'

textpart2="${SKIPLIST}}"

textpart3='"
# Filters.
# jump ahead to continue testing

if [[ "$reponame" =~ ^[a-fh-z] ]]; then
# if [[ "$reponame" =~ ^[9] ]]; then
   echo "skipping ahead X letters"
elif [[ "$skiplist" =~ $reponame ]]; then
    echo "repo in skiplist"
else
    export BOOST_CI_SRC_FOLDER=$(pwd)
    # BOOST_ROOT
    export SELF
    export SELF=python3 "$CI_DIR/get_libname.py"
    runcodecov.sh '

textpart4="${RUNCODECOV_FLAGS}"
textpart5='
    if [[ $? != 0 ]]; then
        echo "..failed. CODECOV FAILED. LIBRARY $reponame"
        echo "$reponame" >> /tmp/failed.txt
    else
        echo "LIBRARY $reponame SUCCEEDED."
        echo "$reponame" >> /tmp/succeeded.txt
    fi
fi
'

textsource="${textpart1}${textpart2}${textpart3}${textpart4}${textpart5}"
echo "$textsource" > /usr/local/bin/runcodecov.sh
chmod 755 /usr/local/bin/runcodecov.sh
echo "checking runcodecov.sh"
cat /usr/local/bin/runcodecov.sh

git submodule foreach 'runcodecov.sh $name'

failed=$(wc -l /tmp/failed.txt | cut -d" " -f1)
succeeded=$(wc -l /tmp/succeeded.txt | cut -d" " -f1)
echo "$failed failed, $succeeded succeeded."
echo ""
cat /tmp/failed.txt
if [ "$failed" != "0" ]; then
    exit 1
fi
