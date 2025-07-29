# Docker postfix + opendkim
A docker container to use postfix for outbound mail sending. Intended for applications that need to send verification/notification mails, but do not need a full mailserver.
It also includes opendkim to sign outgoing mails.

## Deployment

First, create the volume that postfix will use to store its database:
```bash
docker volume create mailer_data
```
Then, download and install the postfix container:
```bash
docker run -d -p 2525:25 -e MAIL_DOMAIN=example.com --name mailer --restart=always -v mailer_data:/data as247/postfix:latest
```
Check login and DKIM key in the logs:
```bash
docker logs mailer
```
The following environment variables are available:
    
```dotenv
MAIL_HOSTNAME=mail.example.com
MAIL_DOMAIN=example.com
MAIL_USER=mailer
MAIL_PASS=mailer123
MAIL_SELECTOR=mail
```

## Using docker-compose
If you prefer to use docker-compose, you can use the following `docker-compose.yml` file:

```yaml
services:
  postfix:
    image: as247/postfix
    environment:
      - MAIL_DOMAIN=${MAIL_DOMAIN}
      - MAIL_USER=${MAIL_USER}
      - MAIL_PASS=${MAIL_PASS}
    ports:
      - "2525:25"
    volumes:
      - postfix_data:/data
    networks:
      - mail_network

volumes:
  postfix_data:
networks:
  mail_network:
    driver: bridge
```