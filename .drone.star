# Use, modification, and distribution are
# subject to the Boost Software License, Version 1.0. (See accompanying
# file LICENSE.txt)
#
# Copyright S. Darwin 2025

# For Drone CI we use the Starlark scripting language to reduce duplication.
# As the yaml syntax for Drone CI is rather limited.
#
#
globalenv={'B2_CI_VERSION': '1', 'B2_VARIANT': 'debug,release', 'B2_FLAGS': 'warnings=extra warnings-as-errors=on'}
linuxglobalimage="cppalliance/droneubuntu2404:1"

def main(ctx):
  return [
  linux_cxx("lcov report", "g++-14", packages="g++-14", buildtype="lcov-report", buildscript="drone", image="cppalliance/droneubuntu2404:1", environment={'LCOV_ERROR_LEVEL': "off", 'B2_TOOLSET': 'gcc-14', 'B2_CXXSTD': '20'}, globalenv=globalenv),
  ]

# from https://github.com/boostorg/boost-ci
load("@boost_ci//ci/drone/:functions.star", "linux_cxx","windows_cxx","osx_cxx","freebsd_cxx")
