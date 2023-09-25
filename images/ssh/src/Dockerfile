FROM alpine:3.15

LABEL "vendor"="Clemens H. Cap"
LABEL "maintainer"="clemens.cap@uni-rostock.de"

    # Upgrade existing packages in the base image
RUN apk update;                   \  
    apk --no-cache upgrade;       \
    apk add --no-cache openssh;   \                                      
    # set a password for user cap TODO: weg   AND ENSURE user has no local password !!!!!
    # disable password authentication for all users
    echo "PasswordAuthentication no " >> /etc/ssh/sshd_config ; \
    # Install sudo, which is not part of alpine, to allow a sudo su for gaining root
    apk add --no-cache sudo;  \
    # clean up any remaining stuff which might be cached 
    rm -rf /var/cache/apk/*   

# copy in the public login key prepared in bin/prepare.sh 
COPY login-key.pub /

# copy in generic entrypoint
COPY entrypoint.sh /

# copy in specific entrypoint
COPY ssh-entry.sh  /

ENTRYPOINT ["/entrypoint.sh"]

# expose port 22 for ssh to work
EXPOSE 22