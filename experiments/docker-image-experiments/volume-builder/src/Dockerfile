FROM lap

# do we really need the full lap for this???

# FROM tex
# FROM alpine: 3.15

LABEL "vendor"="Clemens H. Cap"
LABEL "maintainer"="clemens.cap@uni-rostock.de"


RUN  apk --no-cache update &&   \ 
    apk --no-cache upgrade &&  \
    apk add --no-cache bash 

COPY builder-entrypoint.sh /builder-entrypoint.sh 

# COPY copy-of-script-library.sh /copy-of-script-library.sh

ENTRYPOINT ["/builder-entrypoint.sh"]