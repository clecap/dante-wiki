#!/bin/bash


source /home/dante/dantescript/common-defs.sh

printf "\n*** install-backup called \n"


if [ -z "$DO_SSL_PAGE_BACKUP_CRON" ]; then
  printf "\n${ERROR}NO ssl page backup installed${RESET}"
else
  cron_job="${DO_SSL_PAGE_BACKUP_CRON} /home/dante/dantescript/cron-ssl-page.sh"
  (crontab -l ; echo "$cron_job") | sort - | uniq - | crontab -
  printf "\n${ERROR}NO ssl page backup installed${RESET}"
fi

if [ -z "$DO_AWS_PAGE_BACKUP_CRON" ]; then
  printf "\n${ERROR}NO aws page backup installed${RESET}"
else
  cron_job="${DO_AWS_PAGE_BACKUP_CRON} /home/dante/dantescript/cron-aws-page.sh"
  (crontab -l ; echo "$cron_job") | sort - | uniq - | crontab -
fi