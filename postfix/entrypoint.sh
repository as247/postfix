#!/bin/bash

#load mailer user from env MAIL_USER or default to mailer
randomPassword() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1
}
MAIL_USER=${MAIL_USER:-mailer}

# If MAIL_PASS is not set, generate a random password
if [ -z "$MAIL_PASS" ]; then
  if [ -f /data/mailpass ]; then
    MAIL_PASS=$(cat /data/mailpass)
  else
    #mail pass from env MAIL_PASS or generate random password
    MAIL_PASS=${MAIL_PASS:-$(randomPassword)}
    echo "$MAIL_PASS" > /data/mailpass
  fi
fi

#create MAIL_USER user if not exists and set password
if ! id "$MAIL_USER" &>/dev/null; then
    useradd -m "$MAIL_USER"
fi
echo "$MAIL_USER:$MAIL_PASS" | chpasswd

echo -e "\e[32mSMTP user\e[0m"
echo "******************************************************"
echo "* username: $MAIL_USER"
echo "* password: $MAIL_PASS"
echo "******************************************************"
echo ""
# Configure OpenDKIM
dkim.sh
# Configure and start SASL
sasl.sh
# Configure SSL
ssl.sh
# Configure and start Postfix
postfix.sh

# Start OpenDKIM
service opendkim start
# Start Postfix
postfix start

exec "$@"
