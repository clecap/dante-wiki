FROM lap

LABEL "vendor"="Clemens H. Cap"
LABEL "maintainer"="clemens@clemens-cap.de"

## COPY in docker context
COPY . .

# Expose for http and https (expose is not inherited)
EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]