FROM mysql:latest

# we need timezon information for mysql as well
RUN microdnf update && \
    microdnf install -y tzdata && \
    microdnf clean all


# we want to have the amazon aws command line tools available for backup
RUN microdnf update && \
    microdnf install -y python3 unzip curl && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws && \
    microdnf clean all

# 
# microdnf does not find the package msmtp by itself, we need epel-release for this
# we need msmtp to send mails after a database dump
# we need openssh-clients for ssh-keyen
RUN microdnf update && \
    microdnf install -y wget && \
    microdnf install -y epel-release && \
    microdnf install -y msmtp  openssh-clients && \
    microdnf clean all

COPY . .

# Set default time zone if needed
ENV TZ=UTC

# CMD ["mysqld"]

ENTRYPOINT ["/dante-mysql-entrypoint.sh"]