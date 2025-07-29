#!/bin/bash

# Generate self-signed cert if not exists
CERT_FILE="/etc/ssl/certs/postfix.crt"
KEY_FILE="/etc/ssl/private/postfix.key"
CN="${MAIL_HOSTNAME:-mail.local}"
echo -e "\e[32mSSL\e[0m"
echo "******************************************************"
echo "* Common Name: $CN"
echo "******************************************************"
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  mkdir -p /etc/ssl/certs /etc/ssl/private
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$KEY_FILE" -out "$CERT_FILE" -extensions req_ext \
    -config <(cat <<EOF
[req]
prompt = no
distinguished_name = dn
req_extensions = req_ext

[dn]
CN = $CN

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $CN
DNS.2 = mailer
DNS.3 = localhost
EOF
)

  chmod 600 "$KEY_FILE"
fi

# Configure Postfix TLS
postconf -e "smtpd_tls_cert_file=$CERT_FILE"
postconf -e "smtpd_tls_key_file=$KEY_FILE"
postconf -e "smtpd_tls_security_level=may"
postconf -e "smtpd_tls_auth_only=yes"
postconf -e "smtpd_tls_session_cache_database=btree:\${data_directory}/smtpd_scache"
postconf -e "smtp_tls_session_cache_database=btree:\${data_directory}/smtp_scache"

# Enable submission port 587 with TLS in master.cf if not already present
if ! grep -q "^submission " /etc/postfix/master.cf; then
  cat <<EOF >> /etc/postfix/master.cf

submission inet n       -       n       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
EOF
fi