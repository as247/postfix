# Docker postfix + opendkim
A docker container to use postfix for outbound mail sending. Intended for applications that need to send verification/notification mails, but do not need a full mailserver.
It also includes opendkim to sign outgoing mails.

## Usage

Run the container with the following command:

```bash
docker run \
	-d \
	-e MAIL_DOMAIN=example.com \
	as247/postfix:latest

```

The following environment variables are available:
    
```dotenv
MAIL_HOSTNAME=mail.example.com
MAIL_DOMAIN=example.com
MAIL_USER=mailer
MAIL_PASS=mailer123
```