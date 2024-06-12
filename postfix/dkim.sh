#!/bin/bash

# check if $MAIL_DOMAIN is set
if [ -z "$MAIL_DOMAIN" ]; then
    echo "MAIL_DOMAIN is not set. Skip DKIM."
    exit 1
fi

# Configure OpenDKIM
mkdir -p /data/opendkim/keys

cd /data/opendkim/keys || ( echo "Cannot change directory to /data/opendkim/keys" && exit 1 )

# check for old selector in $MAIL_DOMAIN.txt
if [ -f $MAIL_DOMAIN.txt ]; then
    # get mail key from $MAIL_DOMAIN.txt by get string before ._domainkey
    mailSelectorOld=$(awk -F'.' '!seen && NF {print $1; seen=1}' $MAIL_DOMAIN.txt)
    #trim leading and trailing whitespace
    mailSelectorOld=$(echo $mailSelectorOld | xargs)
fi

#Check if mail selector is set in $MAIL_SELECTOR or $DKIM_SELECTOR
mailSelector=${MAIL_SELECTOR:-${DKIM_SELECTOR}}
if [ -z "$mailSelector" ]; then
    #if mail selector is not set, use old selector or generate new selector
    mailSelector=${mailSelectorOld:-$(date +"m%Y%m%d")}
else
    #if mail selector is set and not equal to old selector, remove old selector files
    if [ -n "$mailSelectorOld" ] && [ "$mailSelectorOld" != "$mailSelector" ]; then
        rm -f $MAIL_DOMAIN.private $MAIL_DOMAIN.txt
    fi
fi

if [ ! -f $MAIL_DOMAIN.private ]; then
    echo "Generating DKIM key for $MAIL_DOMAIN"
    opendkim-genkey -s $mailSelector -d $MAIL_DOMAIN
    mv $mailSelector.private $MAIL_DOMAIN.private
    mv $mailSelector.txt $MAIL_DOMAIN.txt
    #echo $mailSelector > $MAIL_DOMAIN.mailSelector
fi



# Create OpenDKIM configuration
cat <<EOL > /etc/opendkim.conf
AutoRestart             Yes
AutoRestartRate         10/1h
UMask                   002
Syslog                  yes
SyslogSuccess           Yes
LogWhy                  Yes
Canonicalization        relaxed/simple
ExternalIgnoreList      refile:/data/opendkim/trusted.hosts
InternalHosts           refile:/data/opendkim/trusted.hosts
KeyTable                refile:/data/opendkim/key.table
SigningTable            refile:/data/opendkim/signing.table
Mode                    sv
PidFile                 /run/opendkim.pid
SignatureAlgorithm      rsa-sha256
UserID                  opendkim:opendkim
Socket                  inet:8891@localhost
RequireSafeKeys         false

EOL

# Configure key table
cat <<EOL > /data/opendkim/key.table
$mailSelector._domainkey.$MAIL_DOMAIN $MAIL_DOMAIN:$mailSelector:/data/opendkim/keys/$MAIL_DOMAIN.private
EOL

# Configure signing table
cat <<EOL > /data/opendkim/signing.table
*@$MAIL_DOMAIN $mailSelector._domainkey.$MAIL_DOMAIN
EOL

# Configure trusted hosts
cat <<EOL > /data/opendkim/trusted.hosts
0.0.0.0/0
EOL
#chown -R opendkim:opendkim /etc/opendkim/opendkim.conf
chown -R opendkim:opendkim /data/opendkim
chmod -R 0700 /data/opendkim/keys
# Show the DKIM key
dns.sh