FROM alpine:3.15

# Upgrade existing packages in the base image
RUN apk --no-cache upgrade

##
## MUTOOL INSTALLATION
##
     # make a build directory
RUN  mkdir /opt/mutools

     # copy in locally available sources
COPY mupdf-1.20.3-source/ /opt/mutools

     # libraries we need for linking mutool with: libgl1-mesa libglu1.mesa-dev libx11-dev libxi-dev libxrandr-dev
RUN  apk add --no-cache mesa-gl glu libx11 libxi libxrandr && \
     # library headers we need for building mutool with
     apk add --no-cache mesa-dev glu-dev libx11-dev  libxi-dev libxrandr-dev  && \
     # some tools for the build process
     apk add --no-cache gperf g++ make && \
     # got to the build directory
     cd /opt/mutools  && \
     # make
     make && \
     make install && \
     # clean up the build process
     make clean && \
     # remove headers we only required for the build process 
     apk del mesa-dev glu-dev libx11-dev libxi-dev libxrandr-dev && \
     # remove build tools, sources and cached apk artefacts
     apk del gperf g++ make && \
     rm -Rf /opt/mutools && \
     rm -rf /var/cache/apk/* 
##
## END MUTOOL INSTALLATION
##



# Install openssh
RUN apk add --update --no-cache openssh 
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
RUN adduser -h /home/sshuser -s /bin/sh -D sshuser
RUN echo -n 'sshuser:some-password' | chpasswd
ENTRYPOINT ["/entrypoint.sh"]

# copy in a local file
COPY entrypoint.sh /

EXPOSE 22
EXPOSE 80
EXPOSE 443