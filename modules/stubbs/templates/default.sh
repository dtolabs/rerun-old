#!/usr/bin/env bash
#
# NAME
#
#   @NAME@
#
# DESCRIPTION
#
#   @DESCRIPTION@
#

# Read module function library
source $RERUN_MODULES/@MODULE@/lib/functions.sh || exit 1 ;

# Parse the command options
[ -r $RERUN_MODULES/@MODULE@/commands/@NAME@/options.sh ] && {
  source $RERUN_MODULES/@MODULE@/commands/@NAME@/options.sh || exit 2 ;
}


# ------------------------------
# Your implementation goes here.
# ------------------------------

exit $?

# Done
