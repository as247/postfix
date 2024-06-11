#!/usr/bin/env bash

# check if $MAIL_DOMAIN is set
if [ -z "$MAIL_DOMAIN" ]; then
    echo "MAIL_DOMAIN is not set. Skip DKIM."
    exit 1
fi

# Configure OpenDKIM
mkdir -p /etc/opendkim/keys

cd /etc/opendkim/keys

# check if key already exists
if [ ! -f $MAIL_DOMAIN.private ]; then
    echo "Generating DKIM key for $MAIL_DOMAIN"
    #mail key name in format m{year}{monh}{day} eg. m20210801
    mailKey=$(date +"m%Y%m%d")
    opendkim-genkey -s $mailKey -d $MAIL_DOMAIN
    mv $mailKey.private $MAIL_DOMAIN.private
    mv $mailKey.txt $MAIL_DOMAIN.txt
    #echo $mailKey > $MAIL_DOMAIN.mailkey
fi
# get mail key from $MAIL_DOMAIN.txt by get string before ._domainkey
mailKey=$(awk -F'.' '!seen && NF {print $1; seen=1}' $MAIL_DOMAIN.txt)
#trim leading and trailing whitespace
mailKey=$(echo $mailKey | xargs)


# Create OpenDKIM configuration
cat <<EOL > /etc/opendkim.conf
AutoRestart             Yes
AutoRestartRate         10/1h
UMask                   002
Syslog                  yes
SyslogSuccess           Yes
LogWhy                  Yes
Canonicalization        relaxed/simple
ExternalIgnoreList      refile:/etc/opendkim/trusted.hosts
InternalHosts           refile:/etc/opendkim/trusted.hosts
KeyTable                refile:/etc/opendkim/key.table
SigningTable            refile:/etc/opendkim/signing.table
Mode                    sv
PidFile                 /run/opendkim.pid
SignatureAlgorithm      rsa-sha256
UserID                  opendkim:opendkim
Socket                  inet:8891@localhost
RequireSafeKeys         false

EOL

# Configure key table
cat <<EOL > /etc/opendkim/key.table
$mailKey._domainkey.$MAIL_DOMAIN $MAIL_DOMAIN:$mailKey:/etc/opendkim/keys/$MAIL_DOMAIN.private
EOL

# Configure signing table
cat <<EOL > /etc/opendkim/signing.table
*@$MAIL_DOMAIN $mailKey._domainkey.$MAIL_DOMAIN
EOL

# Configure trusted hosts
cat <<EOL > /etc/opendkim/trusted.hosts
0.0.0.0/0
EOL
chown -R opendkim:opendkim /etc/opendkim
chmod -R 0700 /etc/opendkim/keys
# Start OpenDKIM
service opendkim start