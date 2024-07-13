#!/bin/bash


source /home/dante/dantescript/common-defs.sh

printf "\n*** install-mailconfig.sh called \n"


# assume we are called by lap-entrypoint.sh and have a knowledge of the secrets from docker 
# generate a file /home/dante/dantescript/main-config.sh which knows of all the mail configuration parameters
# need to do this like this to protect the secrets a bit better

#!/bin/bash

cat <<EOF > /home/dante/dantescript/mail-config.sh
#!/bin/bash
export SMTP_HOST="${SMTP_HOST}"
export SMTP_PORT=${SMTP_PORT}
export SMTP_USER="${SMTP_USER}"
export SMTP_PASSWORD="${SMTP_PASSWORD}"
export SMTP_FROM="${SMTP_FROM}"
export SMTP_TO="${SMTP_TO}"
EOF

chmod 755 /home/dante/dantescript/mail-config.sh


