#!/bin/bash
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