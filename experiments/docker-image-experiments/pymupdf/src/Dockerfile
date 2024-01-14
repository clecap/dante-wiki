FROM alpine:3.15


# This dockerfile is only meant for testing installation of pymupdf, which is a bit difficult by times
#
#

RUN apk --no-cache upgrade && \
    apk --no-cache add build-base      && \
    apk --no-cache add linux-headers  && \
    apk --no-cache add python3 && \
    apk --no-cache add python3-dev &&\
    ln -sf python3 /usr/bin/python  &&\
    python3 -m ensurepip && \
    pip3 install --no-cache --upgrade pip setuptools &&\
    pip3 install python-config &&\
#    cd /usr/lib/python3.9/config-3.9-x86_64-linux-musl && 
    pip3 install pymupdf 


ENTRYPOINT ["tail", "-f", "/dev/null"]
