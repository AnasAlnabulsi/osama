# Apache Reverse Proxy und Certbot

Apache-Hauptconfig: `vm102/docker/proxy/httpd.conf`.

VirtualHosts:
- `nextcloud.barye.cloudns.asia`
- `nextcloud.hhc.cloudns.asia`
- `collabora.barye.cloudns.asia`

TLS wird am Apache-Proxy terminiert. Intern geht Nextcloud zu `nextcloud:80`
und Collabora zu `collabora:9980`.

Certbot Renewal:
- authenticator `standalone`
- key type `ecdsa`
- Let's Encrypt ACME v2

Private Keys/Zertifikate und Certbot-Account-ID sind nicht enthalten.
