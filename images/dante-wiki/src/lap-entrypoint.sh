#!/bin/bash

# Entrypoint of the dante-wiki image
# Takes as parameters a list of script names residing in /home/dante/dantescript and runs them one after the other.
#
# Each script runs as its own child process, so variables it sets do not survive into the next script.
# Secrets are NOT loaded here: every script that needs them calls loadSecrets itself, so this long-living
# process (PID 1) does not hold the secrets and does not pass them on to scripts that do not need them.
#
# Exit codes of a script:
#   0     success, continue with the next script
#   100   intended shutdown (no error): stop the chain and end the container with exit code 0
#   other error: stop the chain and end the container with this exit code (visible in "docker compose ps")
#
# The last script (normally run-apache.sh) is started with exec, so it replaces this shell and receives
# the stop signal of "docker stop" directly.

source /home/dante/dantescript/common-defs.sh

SCRIPT_DIR=/home/dante/dantescript
SHUTDOWN_CODE=100

printf '\n*** *** This is /lap-entrypoint.sh V3 *** ***\n'
printf '%b*** /lap-entrypoint.sh: Iterating the %s arguments: %s %b\n' "$GREEN" "$#" "$*" "$RESET"

while [ $# -gt 0 ]; do
  script=$1
  shift

  # only plain file names, no paths (prevents ../ tricks)
  if [[ "$script" == */* ]]; then
    printf '\n%b/lap-entrypoint.sh: ERROR: script name %s must not contain a path - ABORTING%b\n' "$ERROR" "$script" "$RESET"
    exit 1
  fi

  if [ ! -f "$SCRIPT_DIR/$script" ]; then
    printf '\n%b/lap-entrypoint.sh: ERROR: file %s not found or not a regular file - ABORTING%b\n' "$ERROR" "$SCRIPT_DIR/$script" "$RESET"
    exit 1
  fi

  bannerGreen "$SCRIPT_DIR/$script ---------- $script "

  # last script: replace this shell, so that it becomes PID 1 and gets the signals of docker stop
  if [ $# -eq 0 ]; then
    exec "$SCRIPT_DIR/$script"
  fi

  "$SCRIPT_DIR/$script"
  EXIT_STATUS=$?

  if [ $EXIT_STATUS -eq $SHUTDOWN_CODE ]; then
    printf '\n%b/lap-entrypoint.sh: %s requested shutdown (exit code %s), shutting down now%b\n' "$ERROR" "$script" "$SHUTDOWN_CODE" "$RESET"
    exit 0
  elif [ $EXIT_STATUS -ne 0 ]; then
    printf '\n%b/lap-entrypoint.sh: %s exited with status %s - ABORTING, remaining scripts are not run%b\n' "$ERROR" "$script" "$EXIT_STATUS" "$RESET"
    exit $EXIT_STATUS
  fi

  printf '%b/lap-entrypoint.sh: %s returned with status 0, moving on%b\n' "$GREEN" "$script" "$RESET"
done

printf '\n\n%blap-entrypoint.sh: Completed all commands.%b\n\n' "$GREEN" "$RESET"
