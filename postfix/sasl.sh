#!/bin/bash
echo "Configuring SASL"
# Configure saslauthd to use shadow for authentication
echo 'NAME="saslauthd"' > /etc/default/saslauthd
echo 'START=yes' >> /etc/default/saslauthd
echo 'MECHANISMS="shadow"' >> /etc/default/saslauthd
echo 'OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"' >> /etc/default/saslauthd

# Enable and start saslauthd
mkdir -p /var/spool/postfix/var/run/saslauthd
rm -rf /var/run/saslauthd
ln -s /var/spool/postfix/var/run/saslauthd /var/run/saslauthd
service saslauthd start
chown -R postfix:postfix /var/spool/postfix/var/run/saslauthd