#!/bin/bash

set -e
set -x

SKIPLIST="math"

: "${LCOV_SKIP_PATTERN:='^[9]'}" # Set default lcov skip pattern

pwd

export CODECOV_SCRIPT=${BOOST_CI_SRC_FOLDER}/ci/travis/codecov.sh
export CI_DIR=${BOOST_CI_SRC_FOLDER}/ci
export BOOST_CI_CODECOV_IO_UPLOAD="skip"
export LCOV_VERSION="v2.3"
export LCOV_IGNORE_ERRORS_LEVEL=standard
export EXPORT_BOOST_SRC_DIR="yes"

touch /tmp/failed.txt
touch /tmp/succeeded.txt

cd "$BOOST_ROOT"
git submodule update --init --recursive
./b2 headers

# The script runcodecov.sh will be pieced together in parts, enabling variables
# to be included into the contents of the script.

# shellcheck disable=SC2016
textpart1='#!/bin/bash
set -x
reponame=$1
echo "reponame is $reponame"
echo "date is $(date)"
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
    # BOOST_ROOT is already set
    export BOOST_CI_SRC_FOLDER=$(pwd)
    SELF=$(python3 "$CI_DIR/get_libname.py")
    if [[ $? != 0 ]]; then
        echo "..failed to determine SELF name of lib"
        echo "$reponame failed to determine SELF variable. May be expected. Continuing." >> /tmp/failed.txt
        exit 0
    fi
    export SELF

    # clean disk space
    rm -rf $BOOST_ROOT/bin.v2/libs

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
    "$CI_DIR"/codecov.sh "upload" 2>&1 | tee /tmp/lcov-repo-results/$reponame
    if [[ $? != 0 ]]; then
        echo "..failed. CODECOV FAILED coverage. LIBRARY $reponame"
        echo "$reponame failed coverage" >> /tmp/failed.txt
    else
        echo "LIBRARY $reponame SUCCEEDED."
        echo "$reponame" >> /tmp/succeeded.txt
    fi

    echo "LIBRARY $reponame RESULTS:" >> /tmp/lcov-results.txt
    grep "lcov: ERROR" /tmp/lcov-repo-results/$reponame >> /tmp/lcov-results.txt || true
    grep "lcov: WARNING" /tmp/lcov-repo-results/$reponame >> /tmp/lcov-results.txt || true
fi
'

textsource="${textpart1}${textpart2}${textpart3}${textpart4}${textpart5}"
echo "$textsource" > /usr/local/bin/runcodecov.sh
chmod 755 /usr/local/bin/runcodecov.sh
echo "checking runcodecov.sh"
cat /usr/local/bin/runcodecov.sh

# shellcheck disable=SC2016
git submodule foreach 'runcodecov.sh $name'

echo " "
echo "The following is a collection of all lcov warnings/errors"
echo " "
cat /tmp/lcov-results.txt
echo " "
echo "The above list is a collection of all lcov warnings/errors"
echo " "

echo " "
echo "The following is a collection of less usual lcov warnings/errors"
echo " "
cat /tmp/lcov-results.txt | grep -v mismatch | grep -v inconsistent | grep -v unused
echo " "
echo "The above list is a collection of less usual lcov warnings/errors"
echo " "


failed=$(wc -l /tmp/failed.txt | cut -d" " -f1)
succeeded=$(wc -l /tmp/succeeded.txt | cut -d" " -f1)
echo "$failed failed, $succeeded succeeded."
echo ""
cat /tmp/failed.txt

sleep 60

echo "Completed"


