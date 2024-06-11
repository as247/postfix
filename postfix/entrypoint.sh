#!/usr/bin/env bash

#load mailer user from env MAIL_USER or default to mailer
randomPassword() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1
}
MAIL_USER=${MAIL_USER:-mailer}

# If MAIL_PASS is not set, generate a random password
if [ -z "$MAIL_PASS" ]; then
  if [ -f /usr/local/mailpass ]; then
    MAIL_PASS=$(cat /usr/local/mailpass)
  else
    #mail pass from env MAIL_PASS or generate random password
    MAIL_PASS=${MAIL_PASS:-$(randomPassword)}
    echo "$MAIL_PASS" > /usr/local/mailpass
  fi
fi

#create MAIL_USER user if not exists and set password
if ! id "$MAIL_USER" &>/dev/null; then
    useradd -m "$MAIL_USER"
fi
echo "$MAIL_USER:$MAIL_PASS" | chpasswd

echo -e "\e[32mCreated user\e[0m $MAIL_USER \e[32mwith password\e[0m $MAIL_PASS"

# Configure saslauthd to use shadow for authentication
echo 'NAME="saslauthd"' > /etc/default/saslauthd
echo 'START=yes' >> /etc/default/saslauthd
echo 'MECHANISMS="shadow"' >> /etc/default/saslauthd
echo 'OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"' >> /etc/default/saslauthd

# Enable and start saslauthd
mkdir -p /var/spool/postfix/var/run/saslauthd
ln -s /var/spool/postfix/var/run/saslauthd /var/run/saslauthd
service saslauthd start
chown -R postfix:postfix /var/spool/postfix/var/run/saslauthd


dkim.sh
dns.sh

# Configure Postfix main.cf
if [ -n "$MAIL_HOSTNAME" ]; then
    postconf -e "myhostname = $MAIL_HOSTNAME"
fi
postconf -e 'smtpd_sasl_auth_enable = yes'
postconf -e 'smtpd_sasl_security_options = noanonymous'
postconf -e 'smtpd_sasl_local_domain = $myhostname'
postconf -e 'broken_sasl_auth_clients = yes'
postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'
postconf -e 'inet_interfaces = all'
# enable dns
postconf -e 'smtp_dns_support_level = dnssec'
postconf -e 'smtp_host_lookup = dns'
postconf -e 'smtp_dns_resolver_options = res_defnames'

#log
postconf -e 'maillog_file = /var/log/mail.log'

# Configure Postfix to use OpenDKIM
if [ -n "$MAIL_DOMAIN" ]; then
    postconf -e "smtpd_milters = inet:127.0.0.1:8891"
    postconf -e "non_smtpd_milters = inet:127.0.0.1:8891"
    postconf -e "milter_default_action = accept"
    postconf -e "milter_protocol = 6"
fi


# Configure SASL
mkdir -p /etc/postfix/sasl
echo 'pwcheck_method: saslauthd' > /etc/postfix/sasl/smtpd.conf
echo 'mech_list: PLAIN LOGIN' >> /etc/postfix/sasl/smtpd.conf

echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf
# Start Postfix
postfix start

exec "$@"
