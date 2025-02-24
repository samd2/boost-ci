#!/bin/bash

set -x
set -e

SKIPLIST=""

: "${LCOV_SKIP_PATTERN:='^[9]'}" # Set default lcov skip pattern

pwd

export CODECOV_SCRIPT=${BOOST_CI_SRC_FOLDER}/ci/travis/codecov.sh
export CI_DIR=${BOOST_CI_SRC_FOLDER}/ci
export BOOST_CI_CODECOV_IO_UPLOAD="skip"

export EXPORT_BOOST_SRC_DIR="yes"

touch /tmp/failed.txt
touch /tmp/succeeded.txt

# mkdir -p /opt/github/boostorg
# cd /opt/github/boostorg
# git clone -b "develop" --depth 1 "https://github.com/boostorg/boost.git"
# cd boost
cd "$BOOST_ROOT"
# clone all submodules
git submodule update --init --recursive

# Run at least one full build that installs everything
# This is failing. Continue for now.
# cd libs/accumulators
# # required vars for codecov.sh:
# export BOOST_CI_SRC_FOLDER=$(pwd)
# export SELF=$(python3 "$CI_DIR/get_libname.py")
# # BOOST_ROOT already set
# $CODECOV_SCRIPT
# cd ../..

# The script runcodecov.sh will be pieced together in parts, enabling variables
# to be included into the contents of the script.

# shellcheck disable=SC2016
textpart1='#!/bin/bash
set -x
reponame=$1
echo "reponame is $reponame"
mkdir -p /tmp/lcov-repo-results || true
skiplist="'

textpart2="${SKIPLIST}"

# shellcheck disable=SC2016
textpart3='"
# Filters.
# jump ahead to continue testing

if [[ "$reponame" =~ '
textpart4="${LCOV_SKIP_PATTERN}"
# shellcheck disable=SC2016
textpart5=' ]]; then
# if [[ "$reponame" =~ ^[9] ]]; then
   echo "skipping ahead X letters"
elif [[ "$skiplist" =~ $reponame ]]; then
    echo "repo in skiplist"
else
    # required vars for codecov.sh:
    export BOOST_CI_SRC_FOLDER=$(pwd)
    export SELF=$(python3 "$CI_DIR/get_libname.py")
    # BOOST_ROOT already set

    # Run the parts of travis/codecov.sh separately:
    source "$CI_DIR"/codecov.sh "setup"
    set +e
    "$CI_DIR"/build.sh
    if [[ $? != 0 ]]; then
        echo "..failed. CODECOV FAILED at build.sh. LIBRARY $reponame"
        echo "$reponame failed build.sh" >> /tmp/failed.txt
    fi
    echo "After build.sh"
    echo "Running codecov.sh upload"
    "$CI_DIR"/codecov.sh "upload" | tee /tmp/lcov-repo-results/$reponame 2>&1
    if [[ $? != 0 ]]; then
        echo "..failed. CODECOV FAILED coverage. LIBRARY $reponame"
        echo "$reponame failed coverage" >> /tmp/failed.txt
    else
        echo "LIBRARY $reponame SUCCEEDED."
        echo "$reponame" >> /tmp/succeeded.txt
    fi

    echo "LIBRARY $reponame RESULTS:" >> /tmp/lcov-results.txt
    grep "geninfo: ERROR" /tmp/lcov-repo-results/$reponame >> /tmp/lcov-results.txt || true
    grep "geninfo: WARNING" /tmp/lcov-repo-results/$reponame >> /tmp/lcov-results.txt || true
fi
'

textsource="${textpart1}${textpart2}${textpart3}${textpart4}${textpart5}"
echo "$textsource" > /usr/local/bin/runcodecov.sh
chmod 755 /usr/local/bin/runcodecov.sh
echo "checking runcodecov.sh"
cat /usr/local/bin/runcodecov.sh

# shellcheck disable=SC2016
git submodule foreach 'runcodecov.sh $name'

failed=$(wc -l /tmp/failed.txt | cut -d" " -f1)
succeeded=$(wc -l /tmp/succeeded.txt | cut -d" " -f1)
echo "$failed failed, $succeeded succeeded."
echo ""
cat /tmp/failed.txt
#
# if [ "$failed" != "0" ]; then
#     exit 1
# fi

cat /tmp/lcov-results.txt
